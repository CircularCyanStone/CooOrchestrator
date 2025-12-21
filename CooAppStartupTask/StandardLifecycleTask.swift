// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：提供预置系统事件的便捷协议与扩展，简化常用生命周期方法的接入。

import Foundation
import UIKit

/// 标准生命周期任务协议（提供预置系统事件的便捷方法）
/// - 开发者可以选择遵守此协议，直接实现 `onLaunch` 等方法，而无需在 `run` 方法中手动 switch phase。
public protocol StandardLifecycleTask: AppLifecycleTask {
    /// App 启动完成（didFinishLaunchingWithOptions）
    func onLaunch(context: LifecycleContext)
    /// App 进入后台（didEnterBackground）
    func onEnterBackground(context: LifecycleContext)
    /// App 进入前台（willEnterForeground）
    func onEnterForeground(context: LifecycleContext)
}

// 提供默认实现（空操作），让用户只需实现感兴趣的方法
public extension StandardLifecycleTask {
    func onLaunch(context: LifecycleContext) {}
    func onEnterBackground(context: LifecycleContext) {}
    func onEnterForeground(context: LifecycleContext) {}
    
    // 自动路由逻辑：实现 AppLifecycleTask 的 run 方法
    func run(context: LifecycleContext) throws -> LifecycleResult {
        switch context.phase {
        case .didFinishLaunchBegin, .didFinishLaunchEnd:
            onLaunch(context: context)
        case .didEnterBackground:
            onEnterBackground(context: context)
        case .willEnterForeground:
            onEnterForeground(context: context)
        default:
            break
        }
        return .continue()
    }
}
