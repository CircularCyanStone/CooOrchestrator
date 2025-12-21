// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义启动任务的核心协议。

import Foundation

/// 启动任务协议
/// - 约束：继承自 NSObject 且符合 Sendable，以支持跨线程调度与反射实例化。
/// - 执行环境：run 方法不绑定特定隔离域（Non-isolated），执行环境跟随调用者（fire 所在的线程）。
public protocol AppLifecycleTask: NSObject, Sendable {
    /// 任务唯一标识，用于日志标记与常驻持有 Map 的键
    static var id: String { get }
    /// 执行时机（如 `didFinishLaunchBegin`）
    static var phase: AppLifecyclePhase { get }
    /// 优先级，数值越大排序越靠前
    static var priority: LifecycleTaskPriority { get }
    /// 执行完成后的持有策略（常驻或自动销毁）
    static var residency: LifecycleTaskRetentionPolicy { get }
    
    /// 必须提供无参构造器，以便管理器反射实例化
    init()
    
    /// 执行任务主体逻辑
    /// - Parameter context: 任务运行上下文（包含环境、参数、共享数据）
    /// - Returns: 执行结果与流程控制指令
    /// - Throws: 允许抛出错误，由管理器捕获并记录日志，不阻断流程
    func run(context: LifecycleContext) throws -> LifecycleResult
}
