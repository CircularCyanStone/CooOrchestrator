// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的升级提示任务，展示在启动早期执行与通过 args 传参的骨架。
// 类型功能描述：UpgradePromptTask 实现 StartupTask 协议，autoDestroy 策略，执行后自动释放。

import Foundation
import CooAppStartupTask

@MainActor
public final class UpgradePromptTask: NSObject, StartupTask {
    public static let id: String = "upgrade.prompt"
    public static let phase: AppStartupPhase = .didFinishLaunchBegin
    public static let priority: StartupTaskPriority = .init(rawValue: 150)
    public static let residency: StartupTaskRetentionPolicy = .destroy​

    private let context: StartupTaskContext
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    public func run() -> StartupTaskResult {
        return .ok
    }
}
