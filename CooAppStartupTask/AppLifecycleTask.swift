// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义启动任务的核心协议。

import Foundation

/// 应用服务协议（原 AppLifecycleTask）
/// - 模块/服务需遵守此协议以接收生命周期事件
public protocol AppService: AnyObject, Sendable {
    
    /// 唯一标识符（默认为类名）
    static var id: String { get }
    
    /// 优先级（默认为 .medium）
    /// - 决定同一事件下多个服务的执行顺序
    static var priority: LifecycleTaskPriority { get }
    
    /// 驻留策略（默认为 .destroy）
    /// - destroy: 执行完即释放（适合一次性任务）
    /// - hold: 首次实例化后常驻内存（适合服务型模块）
    static var retention: LifecycleTaskRetentionPolicy { get }
    
    /// 订阅的生命周期事件集合
    /// - Note: 替代 Manifest 中的 events 配置，支持代码智能提示
    static var events: Set<AppLifecycleEvent> { get }
    
    /// 构造器（需支持无参构造）
    init()
    
    /// 处理生命周期事件
    /// - Parameter context: 包含事件类型、参数及共享数据的上下文
    /// - Returns: 执行结果（.continue 或 .stop）
    func serve(context: LifecycleContext) throws -> LifecycleResult
}

// MARK: - Default Implementation

public extension AppService {
    static var id: String { String(describing: self) }
    static var priority: LifecycleTaskPriority { .medium }
    static var retention: LifecycleTaskRetentionPolicy { .destroy }
    static var events: Set<AppLifecycleEvent> { [.didFinishLaunching] }
}

// 兼容旧名（逐步废弃）
public typealias AppLifecycleTask = AppService
