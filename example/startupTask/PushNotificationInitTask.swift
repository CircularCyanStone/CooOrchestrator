// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的推送初始化任务，展示在 MainActor 上执行并作为 resident 常驻的任务。
// 类型功能描述：PushNotificationInitTask 实现 StartupTask 协议，早期时机执行，优先级高，执行后被调度器持有。

import Foundation
import CooAppStartupTask

@MainActor
public final class PushNotificationInitTask: NSObject, StartupTask {
    public static let id: String = "push.init"
    public static let phase: StartupTaskPhase = .appLaunchEarly
    public static let priority: StartupTaskPriority = .init(rawValue: 200)
    public static let residency: StartupTaskResidency = .resident

    private let context: StartupTaskContext
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    public func run() -> StartupTaskResult {
        return .ok
    }
}
