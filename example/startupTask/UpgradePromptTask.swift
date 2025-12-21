// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的升级提示任务，展示在启动早期执行与通过 args 传参的骨架。
// 类型功能描述：UpgradePromptTask 实现 StartupTask 协议，autoDestroy 策略，执行后自动释放。

import Foundation
import CooAppStartupTask

public final class UpgradePromptTask: NSObject, AppService {
    public static let id: String = "upgrade.prompt"
    public static let priority: LifecycleTaskPriority = .init(rawValue: 150)
    public static let retention: LifecycleTaskRetentionPolicy = .destroy

    // 协议变更
    public required override init() {
        super.init()
    }

    public static func register(in registry: AppServiceRegistry<UpgradePromptTask>) {
        registry.add(.didFinishLaunching) { s, c in
            // 检查更新...
            return .continue()
        }
    }
}
