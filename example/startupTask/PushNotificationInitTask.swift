// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的推送初始化任务，展示在 MainActor 上执行并作为 resident 常驻的任务。
// 类型功能描述：PushNotificationInitTask 实现 StartupTask 协议，早期时机执行，优先级高，执行后被调度器持有。

import Foundation
import CooAppStartupTask

public final class PushNotificationInitTask: NSObject, AppLifecycleTask {
    public static let id: String = "push.init"
    public static let phase: AppLifecyclePhase = .didFinishLaunchBegin
    public static let priority: LifecycleTaskPriority = .init(rawValue: 200)
    public static let residency: LifecycleTaskRetentionPolicy = .hold

    // 协议变更：init 必须无参
    public required override init() {
        super.init()
    }

    // 协议变更：run 接收 context 参数，支持 throws
    public func run(context: LifecycleContext) throws -> LifecycleResult {
        // 使用 context...
        return .ok
    }
}
