# CooOrchestrator Mach-O 注入发现方案 (COSectionDiscovery)

## 1. 概述
`COSectionDiscovery` 是一种基于 **Mach-O Section 注入** 的服务发现方案。它独立于现有的 plist 扫描方案 (`COManifestDiscovery`, `COModuleDiscovery`)，通过在编译期将元数据写入二进制文件的特定段中，并在运行期直接读取内存来实现注册。

该方案支持两种注册粒度：
1.  **模块级 (Module)**: 注册遵循 `COServiceSource` 的模块入口类，由模块自行加载其内部服务。
2.  **服务级 (Service)**: 直接注册遵循 `COService` 的具体服务类，实现更细粒度的解耦。

## 2. 技术方案

### 2.1 存储结构
利用 Mach-O 的 `__DATA` 段，定义两个自定义 Section 以区分注册类型：

*   **Section 1: `__coo_mod`**
    *   用途：存储 **模块入口** 类名。
    *   类型约束：类必须遵循 `COServiceSource` 协议。
    *   数据格式：C 字符串 (UTF-8) 的指针或直接存储定长字符数组。

*   **Section 2: `__coo_svc`**
    *   用途：存储 **具体服务** 类名。
    *   类型约束：类必须遵循 `COService` 协议。
    *   数据格式：C 字符串 (UTF-8) 的指针。

### 2.2 数据记录定义 (C-Layout)
在 Section 中存储的是指向类名字符串的指针（64位系统下为 8 字节地址）。

```c
// 内存布局示意
struct COExportedEntry {
    char *className; 
};
```

### 2.3 注册方式 (Swift)
由于 Swift 缺乏宏支持，需使用 `@_section` 和 `@_used` 属性。

**方式 A: 注册模块 (Module)**
```swift
// MyModuleSource.swift
private let _module_entry: UnsafePointer<CChar> = {
    let name = "MyModuleSource" // 必须是完全限定名 (Module.Class)
    return name.withCString { $0 }
}()

@_used
@_section("__DATA,__coo_mod")
private let _coo_module_ptr = _module_entry
```
*注：上述 Swift 写法在某些编译器版本可能不稳定，建议提供 C/ObjC 辅助宏或推荐标准模板。为简化 Swift 实现，推荐直接存储静态字符串的地址。*

**方式 B: 注册服务 (Service)**
```swift
// MyService.swift
@_used
@_section("__DATA,__coo_svc")
private let _coo_service_entry: UnsafePointer<CChar> = {
    return "MyService".withCString { $0 }
}()
```

### 2.4 发现逻辑 (COSectionDiscovery)
`COSectionDiscovery` 遵循 `COServiceSource` 协议。

**执行流程:**
1.  遍历所有已加载的 Image (利用 `_dyld_image_count`, `_dyld_get_image_header`, `_dyld_get_image_vmaddr_slide`)。
2.  **扫描模块段 (`__coo_mod`)**:
    *   读取类名 -> 实例化 `COServiceSource` -> 调用 `load()` -> 收集 `COServiceDefinition`。
3.  **扫描服务段 (`__coo_svc`)**:
    *   读取类名 -> 实例化 `COService` -> 构造 `COServiceDefinition` (从 `COService` 的静态属性如 `priority`, `retention` 获取配置)。
4.  合并结果并返回。

## 3. 实现细节

### 3.1 内存读取
使用 `getsectbynamefromheader_64` 获取 Section 信息。
*   `addr`: 链接时的虚拟地址。
*   `size`: Section 大小。
*   **真实地址计算**: `real_addr = slide + section->addr`。
*   **读取步长**: 每次读取 `MemoryLayout<UnsafePointer<CChar>>.size` (即 8 字节)。

### 3.2 唯一性与安全
*   使用 `Set<String>` 对读取到的类名进行去重。
*   校验 `NSClassFromString` 返回的类是否遵循对应协议。

## 4. 接口定义

```swift
public struct COSectionDiscovery: COServiceSource {
    public init() {}
    public func load() -> [COServiceDefinition]
}
```

## 5. 优势
*   **无中心化配置**: 不需要维护 plist。
*   **高性能**: 直接内存读取，无需文件 IO 和 XML/Plist 解析。
*   **灵活性**: 同时支持粗粒度(Module)和细粒度(Service)注册。

