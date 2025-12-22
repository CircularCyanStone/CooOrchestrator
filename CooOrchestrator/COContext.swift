// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义服务执行的上下文环境，封装事件参数、共享数据与静态配置。
// 类型功能描述：COContext 是贯穿整个责任链的核心数据对象，承载了运行时环境与用户数据。

import Foundation

/// 线程安全的共享数据容器
public final class COContextUserInfo: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Any] = [:]
    
    public init() {}
    
    public func get<T>(_ key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key] as? T
    }
    
    public func set(_ key: String, value: Any) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
    
    /// 批量合并（用于初始化等场景）
    public func merge(_ other: [String: Any]) {
        lock.lock()
        defer { lock.unlock() }
        storage.merge(other) { _, new in new }
    }
}

/// 服务运行上下文（引用类型，支持责任链数据共享）
/// - Note: 使用 COContextUserInfo 确保多线程环境下的数据安全
/// - Note: 标记为 @unchecked Sendable 以支持携带非 Sendable 的系统对象参数（如 UIApplication）
public final class COContext: @unchecked Sendable {
    /// 当前触发的生命周期事件
    public let event: COEvent
    /// 运行环境（如 bundle 等）
    public let environment: AppEnvironment
    /// 通过清单传入的静态参数集合
    public let args: [String: Sendable]
    /// 动态事件参数（如 application, launchOptions 等）
    public let parameters: [COParameterKey: Any]
    /// 动态共享数据（线程安全）
    public let userInfo: COContextUserInfo
    
    /// 上下文构造器
    /// - Parameters:
    ///   - event: 当前事件
    ///   - environment: 运行环境
    ///   - args: 服务参数
    ///   - parameters: 动态事件参数
    ///   - userInfo: 共享数据容器（默认自动创建）
    public init(event: COEvent,
                environment: AppEnvironment,
                args: [String: Sendable] = [:],
                parameters: [COParameterKey: Any] = [:],
                userInfo: COContextUserInfo = .init()) {
        self.event = event
        self.environment = environment
        self.args = args
        self.parameters = parameters
        self.userInfo = userInfo
    }
}


