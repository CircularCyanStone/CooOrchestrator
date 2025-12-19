// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例任务——截屏提示任务，展示在 didFinishLaunching 末尾时机执行一次的轻量任务。
// 类型功能描述：ScreenshotTipTask 实现 StartupTask 协议，autoDestroy 策略，执行后自动释放。

import Foundation

@MainActor
public final class ScreenshotTipTask: NSObject, StartupTask {
    /// 任务标识：截屏提示
    public static let id: String = "screenshot.tip"
    /// 执行时机：应用启动末尾（`didFinishLaunching` 即将返回时）
    public static let phase: StartupTaskPhase = .appLaunchLate
    /// 优先级：中等，通常晚于推送初始化等关键任务
    public static let priority: StartupTaskPriority = .init(rawValue: 100)
    /// 常驻策略：autoDestroy，执行一次后立即释放
    public static let residency: StartupTaskResidency = .autoDestroy

    /// 执行所需的上下文信息（环境与参数）
    private let context: StartupTaskContext
    /// 通过上下文构造任务实例
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    /// 执行截屏提示相关逻辑（示例中仅返回成功）
    public func run() -> StartupTaskResult {
        return .ok
    }
}
