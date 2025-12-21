// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义任务运行上下文及其相关环境数据结构，支持线程安全的数据共享。

import Foundation

/// 线程安全的共享数据容器
public final class LifecycleContextUserInfo: @unchecked Sendable {
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

/// 任务运行上下文（引用类型，支持责任链数据共享）
/// - Note: 使用 LifecycleContextUserInfo 确保多线程环境下的数据安全
/// - Note: 标记为 @unchecked Sendable 以支持携带非 Sendable 的系统对象参数（如 UIApplication）
public final class LifecycleContext: @unchecked Sendable {
    /// 当前触发的生命周期阶段
    public let phase: AppLifecyclePhase
    /// 运行环境（如 bundle 等）
    public let environment: AppEnvironment
    /// 通过清单传入的静态参数集合
    public let args: [String: Sendable]
    /// 动态事件参数（如 application, launchOptions 等）
    public let parameters: [LifecycleParameterKey: Any]
    /// 动态共享数据（线程安全）
    public let userInfo: LifecycleContextUserInfo
    
    /// 上下文构造器
    /// - Parameters:
    ///   - phase: 当前阶段
    ///   - environment: 运行环境
    ///   - args: 任务参数
    ///   - parameters: 动态事件参数
    ///   - userInfo: 共享数据容器（默认自动创建）
    public init(phase: AppLifecyclePhase,
                environment: AppEnvironment,
                args: [String: Sendable] = [:],
                parameters: [LifecycleParameterKey: Any] = [:],
                userInfo: LifecycleContextUserInfo = .init()) {
        self.phase = phase
        self.environment = environment
        self.args = args
        self.parameters = parameters
        self.userInfo = userInfo
    }
}

/// 基础运行环境
public struct AppEnvironment: Sendable {
    /// 运行的主 Bundle（默认 `.main`）
    public let bundle: Bundle
    /// 环境构造器
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
}
