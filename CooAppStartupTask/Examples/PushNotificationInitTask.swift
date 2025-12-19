// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例任务——推送初始化任务，展示如何声明任务元数据与在 MainActor 上同步执行。
// 类型功能描述：PushNotificationInitTask 实现 StartupTask 协议，使用 resident 策略以便在会话期内提供后续能力。

import Foundation

@MainActor
public final class PushNotificationInitTask: NSObject, StartupTask {
    /// 任务标识：推送初始化
    public static let id: String = "push.init"
    /// 执行时机：应用启动早期（`didFinishLaunching` 开始阶段）
    public static let phase: StartupTaskPhase = .appLaunchEarly
    /// 优先级：较高，优先完成推送初始化
    public static let priority: StartupTaskPriority = .init(rawValue: 200)
    /// 常驻策略：resident，执行后保持实例以支撑后续能力
    public static let residency: StartupTaskResidency = .resident

    /// 执行所需的上下文信息（环境与参数）
    private let context: StartupTaskContext
    /// 通过上下文构造任务实例
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    /// 执行推送相关初始化逻辑（示例中仅返回成功）
    public func run() -> StartupTaskResult {
        return .ok
    }
}
