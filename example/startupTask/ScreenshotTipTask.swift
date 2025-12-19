// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的截屏提示任务，展示在 didFinishLaunching 末尾时机执行一次的轻量任务。
// 类型功能描述：ScreenshotTipTask 实现 StartupTask 协议，autoDestroy 策略，执行后自动释放。

import Foundation
import CooAppStartupTask

@MainActor
public final class ScreenshotTipTask: NSObject, StartupTask {
    public static let id: String = "screenshot.tip"
    public static let phase: StartupTaskPhase = .appLaunchLate
    public static let priority: StartupTaskPriority = .init(rawValue: 100)
    public static let residency: StartupTaskResidency = .autoDestroy

    private let context: StartupTaskContext
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    public func run() -> StartupTaskResult {
        return .ok
    }
}

