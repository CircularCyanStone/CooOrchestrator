// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的推送初始化任务，展示在 MainActor 上执行并作为 resident 常驻的任务。
// 类型功能描述：PushNotificationInitTask 实现 StartupTask 协议，早期时机执行，优先级高，执行后被调度器持有。

import Foundation
import CooAppStartupTask

public final class PushNotificationInitTask: NSObject, AppService {
    public static let id: String = "push.init"
    public static let priority: LifecycleTaskPriority = .init(rawValue: 200)
    public static let retention: LifecycleTaskRetentionPolicy = .hold
    
    // 协议变更：init 必须无参
    public required override init() {
        super.init()
    }

    // 协议变更：注册事件处理
    public static func register(in registry: AppServiceRegistry<PushNotificationInitTask>) {
        // 注册启动事件
        registry.add(.didFinishLaunching) { service, context in
            // 初始化推送 SDK
            print("PushNotificationInitTask: Initializing SDK...")
            return .continue()
        }
        
        // 注册推送注册成功事件
        registry.add(.didRegisterForRemoteNotifications) { service, context in
            guard let token = context.parameters[.deviceToken] as? Data else { return .continue() }
            print("PushNotificationInitTask: Registered token: \(token)")
            return .continue()
        }
    }
}
