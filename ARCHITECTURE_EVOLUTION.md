# CooAppStartupTask 架构演进与重构规划

## 1. 核心理念转变

### 1.1 现状：启动任务管理器 (Startup Task Manager)
目前的组件设计定位为一个纯粹的 **App 启动流程管理器**。
*   **核心职责**：在 `didFinishLaunchingWithOptions` 阶段，按优先级顺序执行一系列初始化代码。
*   **局限性**：随着模块化程度加深，业务模块不仅需要在启动时初始化，还需要感知 App 的全生命周期（如切后台、切前台、处理 URL Scheme、接收推送等）。目前的架构导致这些事件依然需要在 `AppDelegate` 或 `SceneDelegate` 中手动分发，破坏了模块的封装性。

### 1.2 目标：应用生命周期分发中心 (App Lifecycle Dispatcher)
将组件升级为一个通用的 **事件总线系统**，专门用于分发系统级生命周期事件。
*   **新核心职责**：作为主工程（Host App）与各业务模块（Modules）之间的中间件，将 `AppDelegate` 和 `SceneDelegate` 接收到的系统事件，解耦地分发给所有感兴趣的模块。
*   **价值**：
    *   **高内聚**：模块内部自闭环管理所有生命周期逻辑。
    *   **低耦合**：主工程无需 import 业务模块，无需硬编码调用生命周期方法。
    *   **可插拔**：通过配置（Plist/Discovery）即可插拔模块，无需修改主工程代码。

---

## 2. 架构设计演进

### 2.1 核心抽象层升级

| 概念 | 当前实现 (StartupTask) | 目标实现 (LifecycleTask) | 备注 |
| :--- | :--- | :--- | :--- |
| **协议定义** | `StartupTask` | `AppLifecycleTask` | 需泛化，不再局限于“启动” |
| **执行时机** | `AppStartupPhase` (didFinishLaunch) | `AppLifecyclePhase` | 扩展支持 `didEnterBackground`, `sceneDidBecomeActive`, `openURL` 等 |
| **上下文** | `StartupTaskContext` (Environment + Args) | `LifecycleContext` | 需支持携带动态 payload (如 URL, Notification, UserInfo) |
| **执行结果** | `StartupTaskResult` (Success/Fail) | `LifecycleResult` | 需支持聚合策略 (如 `openURL` 需汇总 Bool 返回值) |
| **实例管理** | `RetentionPolicy` (Destroy/Hold) | `RetentionPolicy` | **Hold** 策略将成为主流，模块需常驻以监听后续事件 |

### 2.2 关键技术点

#### A. 阶段定义的泛化
已将 `Phase` 从 `Enum` 重构为 `Struct (RawRepresentable)`，支持无限扩展。
- **预设系统事件**：框架内置常用生命周期（Launch, Background, Terminate）。
- **自定义事件**：业务方可扩展（如 `UserDidLogin`, `ThemeDidChange`）。

#### B. 上下文 (Context) 的多态性与数据共享
不同事件携带的参数不同，且在责任链传播过程中，上游模块可能需要向下游模块传递处理结果（如 URL 解析后的参数）。

**设计方案**：
将 `StartupTaskContext` 升级为引用类型（Class），并引入 `userInfo` 容器。

```swift
public final class LifecycleContext: @unchecked Sendable {
    /// 运行环境（只读）
    public let environment: AppEnvironment
    /// 静态参数（来自 plist）
    public let args: [String: Sendable]
    /// 动态共享数据（读写）
    /// 用于责任链中上下游传递数据，例如 Router 模块解析 URL 后将参数放入此处，供业务模块读取。
    /// 使用 NSMutableDictionary 确保在责任链中传递的是同一个引用容器。
    public let userInfo: NSMutableDictionary
    
    // ... init ...
}
```

#### C. 流程控制与结果聚合 (Flow Control & Result)
借鉴经典的责任链模式（如 DTFrameworkCallbackResult），引入对事件传播的控制能力。

**设计方案**：
利用 Swift 枚举关联值，实现灵活的“继续/中断”控制。

```swift
/// 生命周期任务的执行结果
public enum LifecycleResult: Sendable {
    /// 继续传播：当前任务执行完毕，继续执行后续优先级的任务
    /// - success: 任务执行是否成功（用于日志）
    /// - message: 日志信息
    case `continue`(success: Bool = true, message: String? = nil)
    
    /// 中断传播：不再执行后续任务（独占处理）
    /// 对应 DTFrameworkCallbackResultReturn / ReturnYES / ReturnNO
    /// - result: 最终返回给系统的值（默认为 .void）
    /// - success: 任务执行是否成功
    case stop(result: LifecycleReturnValue = .void, success: Bool = true, message: String? = nil)
}

/// 系统代理方法的返回值封装
public enum LifecycleReturnValue: Sendable {
    case void          // 无返回值 (void)
    case bool(Bool)    // 布尔返回值 (openURL -> Bool)
    // 可扩展其他类型
}
```

**调度逻辑**：
管理器在遍历执行任务时，需检查每个任务的返回结果：
- 若为 `.continue`：继续执行下一个任务。
- 若为 `.stop`：立即终止循环，并将关联的 `value` 返回给调用方（AppDelegate）。

#### D. 管理器 (Manager) 的职责升级
`StartupTaskManager` 需升级为通用分发器。
- **Shared Context**: 每次 `fire` 时，创建一个新的 `NSMutableDictionary` 作为 `userInfo` 容器，传递给所有任务的 Context，确保数据在单次调用链中共享。
- **Return Value**: `fire` 方法需要支持返回值，以反馈给系统代理（如 `openURL` 需返回 Bool）。

#### E. 接口设计策略：单一分发方法 (Single Dispatch)

**决策**：采用 **单一方法 + 事件类型** 的模式，而非为每个事件定义单独的协议方法。

```swift
protocol AppLifecycleTask {
    // 统一入口，通过 switch context.phase 处理不同事件
    func run(context: LifecycleContext) -> LifecycleResult
}
```

**理由**：
1.  **无限扩展性**：支持自定义事件（如 `userDidLogin`），无需修改协议定义或 Manager 源码。
2.  **动态调度**：完美契合 `Manifest` 驱动的架构，Manager 无需感知具体事件类型，只负责透传。

**类型安全补偿**：
虽然单一方法导致参数弱类型化（都在 `parameters` 字典里），但可以通过 **Context 扩展** 来弥补。

```swift
// 框架提供的强类型辅助扩展
extension LifecycleContext {
    /// 获取 OpenURL 事件的专用参数
    public var openURLParameters: (url: URL, options: [UIApplication.OpenURLOptionsKey: Any])? {
        guard let url = parameters["url"] as? URL else { return nil }
        let options = parameters["options"] as? [UIApplication.OpenURLOptionsKey: Any] ?? [:]
        return (url, options)
    }
}
```

---

## 3. 实施路线图 (Roadmap)

### 阶段一：理念验证 (POC) - **当前阶段**
- [x] 分析当前架构局限性。
- [x] 将 `Phase` 重构为可扩展结构体。
- [ ] 文档化架构愿景（本文档）。

### 阶段二：核心重构
- [ ] **重命名与抽象**：逐步将 `StartupTask` 概念迁移至 `AppLifecycleTask`。保持向下兼容（typealias）。
- [ ] **增强 Context**：支持传递 `launchOptions`, `url`, `notification` 等系统参数。
- [ ] **扩展 Manager**：支持 `dispatch(_ phase: Phase, context: Context)` 通用分发接口。

### 阶段三：场景落地
- [ ] **SceneDelegate 支持**：接入 `sceneDidBecomeActive` 和 `sceneWillResignActive`。
- [ ] **URL 路由分发**：实现 `openURL` 的去中心化分发，验证返回值聚合逻辑。

#### G. 稳定性与健壮性设计

**1. 并发模型 (Concurrency Model)**
*   **目标**：支持多线程同步分发（如后台下载回调、推送），避免强制切主线程导致无法获取返回值。
*   **策略**：**非隔离设计 (Non-isolated Design) + GCD 串行队列保护**。
    *   `Manager`：不标记为 `@MainActor`。
    *   **内部状态保护**：持有一个私有的串行队列 (`DispatchQueue`)。所有对内部状态（任务列表、常驻实例）的读写操作，均通过该队列进行调度（读用 `sync`，写用 `async`）。
    *   **执行逻辑**：`fire` 方法在读取任务列表时使用队列同步，但在**执行任务 (`task.run`) 时脱离队列**，在调用者线程直接执行，以避免死锁和环境切换。
    *   `AppLifecycleTask`：协议移除 `@MainActor` 约束，继承 `Sendable`。
*   **Context 安全性**：
    *   `LifecycleContext` 必须是 `Sendable`。
    *   内部 `userInfo` 容器需封装为线程安全的字典（使用 `NSLock` 或读写锁保护），允许存储 `Any`。

**2. 异常隔离 (Exception Isolation)**
*   **协议升级**：`run` 方法签名增加 `throws`。
    ```swift
    func run(context: LifecycleContext) throws -> LifecycleResult
    ```
*   **容错机制**：Manager 在调用任务时必须包裹在 `do-catch` 块中。
    *   若任务抛出错误，Manager 捕获该错误，记录 Error 级别的日志，并**自动继续执行下一个任务**（视为返回了 `.continue`），确保单一模块的崩溃不会阻断整个 App 的启动流程。

**3. 循环调用保护**
*   Manager 内部维护一个简单的递归深度计数器。若检测到嵌套分发深度超过阈值（如 10 层），自动中断并报错，防止 Stack Overflow。

---

## 5. 实施路线图 (Revised)

1.  **异步处理原则**：维持框架本身的**同步调度**特性。
    - **原因**：系统生命周期代理方法绝大多数是同步的（尤其是启动和 UI 相关）。
    - **规范**：如果模块需要执行耗时操作（网络/IO），应在 `run` 方法内部自行派发到后台队列，不要阻塞主线程。

2.  **配置化优先**：继续坚持 `ManifestDiscovery` 机制。
    - **优势**：这是实现“模块可插拔”的关键。模块是否存在，完全由 Plist 配置决定，主工程无需任何代码引用。

3.  **调试与监控**：
    - 随着分发事件增多，日志量会剧增。需要优化 `Logging` 模块，支持按 Phase 或 Module 过滤日志，甚至提供可视化的生命周期泳道图工具。
