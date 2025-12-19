// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例任务——升级提示任务，展示在 early 时机执行的提示逻辑骨架。
// 类型功能描述：UpgradePromptTask 实现 StartupTask 协议，autoDestroy 策略；通过 args 演示参数传入。

import Foundation

@MainActor
/// 升级提示任务（示例）
/// - 说明：展示在 early 时机执行、使用 `args` 传参的任务骨架
public final class UpgradePromptTask: NSObject, StartupTask {
    /// 任务标识
    public static let id: String = "upgrade.prompt"
    /// 执行时机：启动早期
    public static let phase: StartupTaskPhase = .appLaunchEarly
    /// 优先级：150
    public static let priority: StartupTaskPriority = .init(rawValue: 150)
    /// 执行后自动释放
    public static let residency: StartupTaskResidency = .autoDestroy

    /// 由调度器注入的上下文
    private let context: StartupTaskContext
    /// 上下文构造器
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    /// 执行升级检查与提示逻辑（示例返回成功）
    public func run() -> StartupTaskResult {
        return .ok
    }
}
