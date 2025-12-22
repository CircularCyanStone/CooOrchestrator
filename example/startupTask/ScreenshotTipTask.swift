// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：示例工程中的截屏提示任务，展示在 didFinishLaunching 末尾时机执行一次的轻量任务。
// 类型功能描述：ScreenshotTipTask 实现 StartupTask 协议，autoDestroy 策略，执行后自动释放。

import Foundation
import UIKit
import CooOrchestrator

public final class ScreenshotTipTask: NSObject, COService {
    public static let id: String = "screenshot.tip"
    public static let priority: COPriority = .init(rawValue: 100)
    public static let retention: CORetentionPolicy = .destroy

    // 协议变更
    public required override init() {
        super.init()
    }

    public static func register(in registry: CORegistry<ScreenshotTipTask>) {
        registry.add(.didFinishLaunchEnd) { s, c in
            // 处理逻辑...
            print("========")
            return .continue()
        }
        addScene(.sceneWillConnect, in: registry)
    }
}
extension ScreenshotTipTask: COSceneObserver {
    
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> COResult {
        print("========")
        return .continue(success: true)
    }
}
