# 模块注册方案探讨与分析

本文档旨在探讨 **CooOrchestrator** 在多模块架构下的服务注册方案，旨在解决当前脚本扫描方案（`COManifestDiscovery`）对二进制/静态库支持不佳以及全局扫描带来的启动耗时问题。

## 背景痛点

当前 `COManifestDiscovery` 采用全量扫描 `Frameworks` 和 `Resources` 目录下的 Plist 文件来发现服务。存在以下问题：
1.  **二进制支持弱**：静态链接库（Static Library）合并入主包后，原有 Bundle 结构丢失，导致无法扫描到其内部的 Plist。
2.  **启动耗时**：随着模块数量增加，I/O 操作（遍历目录、读取文件）和 Plist 解析耗时线性增长。
3.  **不稳定**：依赖字符串反射，且资源文件拷贝路径容易出错。

---

## 方案一：基于 Mach-O Section 的自动注册（备选）

利用编译器特性，将服务注册信息直接写入二进制文件的特定数据段（Section），实现“无文件、无扫描”的自动注册。

### 核心原理
1.  **编译期**：通过 C 宏或 Swift 属性（如 `@_section`），在编译时将服务类的元数据（类名、优先级等）写入 Mach-O 文件的 `__DATA` 段中名为 `__co_services` 的自定义 Section。
2.  **启动期**：`COOrchestrator` 通过 `dyld` API 直接读取内存中该 Section 的数据，获取所有服务列表。

### 优缺点
*   **优点**：极致解耦，无文件 I/O，支持所有链接形式。
*   **缺点**：实现复杂，需处理链接器 Strip 问题，维护成本较高。

---

### 核心定位与设计目标
*   **首要目标 (Must)**：**解耦**。
    *   **主工程与服务解耦**：主工程不需要 import 具体服务的业务模块，也不需要手动实例化服务。
    *   **模块与模块解耦**：A 模块不需要依赖 B 模块，通过服务协议进行通信。
    *   **模块与工程解耦**：模块可以独立开发、测试，不强依赖主工程的配置环境。
*   **次要目标 (Nice to have)**：**自动收集**。
    *   “自动收集实现协议的服务”属于**锦上添花**的便捷特性，并非框架的核心基石。
    *   在二进制支持、启动性能等核心工程约束面前，为了“自动”而引入高昂代价（如全量扫描、复杂 Hook）是不可取的。
    *   因此，方案选择上优先保证**显式、确定、高效**的注册路径。

---

## 方案二：模块入口协议 + 主应用配置表（推荐）

**核心思想**：放弃“全自动发现具体服务”，转为“显式管理模块”。主应用只负责加载“模块入口”，具体服务由模块内部纯代码注册。

### 核心原理
1.  **模块内（纯代码）**：每个功能模块提供一个遵循 `COModule` 协议的入口类，在 `registerServices()` 方法中通过纯代码（`COOrchestrator.shared.register(...)`）注册该模块的所有服务。
2.  **主应用（Plist 配置）**：主工程维护一份 `COModules.plist`，仅列出需要加载的**模块入口类名**。
3.  **启动期**：框架读取 `COModules.plist` -> 反射实例化模块入口 -> 调用模块的 `registerServices()`。

### 代码形态示例

**1. 模块侧 (ModuleA)**
```swift
// 模块内完全不需要解耦，直接引用具体类，编译期安全
public class ModuleAEntry: COModule {
    public static func registerServices() {
        // 纯代码注册，无反射，无文件读取
        // 这一步仅是将 Descriptor 存入内存，速度极快
        COOrchestrator.shared.register(service: UserServiceImpl.self, priority: .high)
        COOrchestrator.shared.register(service: PaymentServiceImpl.self)
    }
}
```

**2. 主应用侧 (Main App)**
*   配置 `COModules.plist`:
    *   `Item 0`: `ModuleAEntry`
    *   `Item 1`: `ModuleBEntry`

### 深度分析与关键结论

#### 1. 性能真相：注册 ≠ 初始化
*   **观点确认**：**不应在模块（Module）级别做异步或懒加载控制**。
*   **原因**：`COOrchestrator.register` 仅仅是将服务描述符（Descriptor）存入内存字典中，这是一个极轻量级的纯内存操作（微秒级）。
*   **结论**：即使主应用启动时连续调用 100 个模块的 `registerServices`，总耗时也可以忽略不计。真正影响启动耗时的是**具体 Service 的执行逻辑**。
*   **策略**：
    *   模块注册（`registerServices`）：在启动时**同步全量执行**。
    *   耗时控制：下沉到 **Service 粒度**。由 Service 自身定义的 `COEvent`（如 `boot` vs `idle`）和 `priority` 来决定它何时运行。

#### 2. 配置管理：显式优于隐式
*   **策略**：在主工程的 `COModules.plist` 中**显式维护**模块入口列表。
*   **优势**：
    *   **确定性**：明确知道集成了哪些模块，避免脚本扫描二进制文件的技术黑洞。
    *   **容错性**：允许配置表中存在当前 Target 未链接的模块（框架层 catch 异常并忽略），从而实现一份配置适配多个 App 变体。

#### 3. 类型安全与开发体验
*   **现状确认**：框架核心层 (`COrchestrator`) 已提供泛型注册 API `register<T: COService>(service: T.Type, ...)`。
*   **策略**：**充分利用现有能力**。在新的模块入口协议（`COModule`）的实践中，强制或推荐使用该泛型 API。
*   **优势**：直接复用已有设计，无需新开发。模块内注册代码将天然具备编译期类型安全，避免了 `NSClassFromString` 的隐患。

### 总结建议
采用 **方案二**，并明确：
1.  **模块入口**只负责“填表”，不做重操作，启动时全量同步加载。
2.  **主应用**通过 Plist 显式管理模块列表。
3.  **服务调度**依靠 Service 自身的 Event/Priority 配置，而非模块级开关。
