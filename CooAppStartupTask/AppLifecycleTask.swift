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
    
    /// 注册服务事件
    /// - Parameter registry: 注册器，用于绑定事件处理闭包
    static func register(in registry: AppServiceRegistry<Self>)
    
    /// 构造器（需支持无参构造）
    init()
}

// MARK: - Registry

/// 服务注册器
/// - 用于在应用启动时收集各服务的事件绑定关系
public final class AppServiceRegistry<Service: AppService>: Sendable {
    
    /// 内部使用的事件处理闭包
    /// 使用 Any AppService 以便在 Manager 中通用存储
    public typealias Handler = @Sendable (Service, LifecycleContext) throws -> LifecycleResult
    
    /// 注册项（内部使用）
    public struct Entry: Sendable {
        let event: AppLifecycleEvent
        let handler: @Sendable (any AppService, LifecycleContext) throws -> LifecycleResult
    }
    
    // 线程安全的存储（实际上 Registry 仅在 Serial Queue 中同步使用，但为了 Sendable 标记）
    private let lock = NSLock()
    private var _entries: [Entry] = []
    
    var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }
    
    public init() {}
    
    /// 注册事件处理
    /// - Parameters:
    ///   - event: 关注的事件
    ///   - handler: 处理闭包
    public func add(_ event: AppLifecycleEvent, handler: @escaping Handler) {
        lock.lock()
        defer { lock.unlock() }
        
        // 封装闭包以支持类型擦除
        let anyHandler: @Sendable (any AppService, LifecycleContext) throws -> LifecycleResult = { service, context in
            guard let specificService = service as? Service else {
                // 理论上不会发生，除非 Manager 逻辑错误
                return .continue()
            }
            return try handler(specificService, context)
        }
        
        _entries.append(Entry(event: event, handler: anyHandler))
    }
    
    /// 注册事件处理（支持 Void 返回值的便捷方法）
    public func add(_ event: AppLifecycleEvent, handler: @escaping @Sendable (Service, LifecycleContext) throws -> Void) {
        add(event) { service, context in
            try handler(service, context)
            return .continue()
        }
    }
}

// MARK: - Default Implementation

public extension AppService {
    static var id: String { String(describing: self) }
    static var priority: LifecycleTaskPriority { .medium }
    static var retention: LifecycleTaskRetentionPolicy { .destroy }
}

// 兼容旧名（逐步废弃）
public typealias AppLifecycleTask = AppService
