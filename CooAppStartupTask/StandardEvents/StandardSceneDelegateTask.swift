// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：提供 UIWindowSceneDelegate 预置事件的便捷协议与扩展。

import Foundation
import UIKit

/// 标准 SceneDelegate 生命周期任务协议
/// - 适用于 iOS 13+ 的多窗口场景
/// - 开发者可以选择遵守此协议，直接实现对应的生命周期方法
public protocol StandardSceneDelegateTask: AppLifecycleTask {
    
    // MARK: - Scene Life Cycle
    
    /// Scene 连接 (scene:willConnectTo:options:)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> LifecycleResult
    
    /// Scene 断开 (sceneDidDisconnect)
    func sceneDidDisconnect(_ scene: UIScene) -> LifecycleResult
    
    /// Scene 激活 (sceneDidBecomeActive)
    func sceneDidBecomeActive(_ scene: UIScene) -> LifecycleResult
    
    /// Scene 取消激活 (sceneWillResignActive)
    func sceneWillResignActive(_ scene: UIScene) -> LifecycleResult
    
    /// Scene 进入前台 (sceneWillEnterForeground)
    func sceneWillEnterForeground(_ scene: UIScene) -> LifecycleResult
    
    /// Scene 进入后台 (sceneDidEnterBackground)
    func sceneDidEnterBackground(_ scene: UIScene) -> LifecycleResult
    
    // MARK: - Scene Events
    
    /// 打开 URL 上下文 (scene:openURLContexts:)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> LifecycleResult
    
    /// 继续用户活动 (scene:continue:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> LifecycleResult
    
    /// 更新用户活动 (scene:didUpdate:)
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> LifecycleResult
    
    /// 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> LifecycleResult
    
    /// 状态恢复 (stateRestorationActivity(for:))
    func stateRestorationActivity(for scene: UIScene) -> LifecycleResult
}

// MARK: - Default Implementation & Routing

public extension StandardSceneDelegateTask {
    
    // MARK: Default Implementations
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> LifecycleResult { .continue() }
    func sceneDidDisconnect(_ scene: UIScene) -> LifecycleResult { .continue() }
    func sceneDidBecomeActive(_ scene: UIScene) -> LifecycleResult { .continue() }
    func sceneWillResignActive(_ scene: UIScene) -> LifecycleResult { .continue() }
    func sceneWillEnterForeground(_ scene: UIScene) -> LifecycleResult { .continue() }
    func sceneDidEnterBackground(_ scene: UIScene) -> LifecycleResult { .continue() }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> LifecycleResult { .continue() }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> LifecycleResult { .continue() }
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> LifecycleResult { .continue() }
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> LifecycleResult { .continue() }
    func stateRestorationActivity(for scene: UIScene) -> LifecycleResult { .continue() }
    
    // MARK: - Auto Routing
    
    func serve(context: LifecycleContext) throws -> LifecycleResult {
        guard let scene = context.parameters[.scene] as? UIScene else {
            return .continue()
        }
        
        switch context.event {
        case .sceneWillConnect:
            guard let session = context.parameters[.session] as? UISceneSession,
                  let options = context.parameters[.connectionOptions] as? UIScene.ConnectionOptions else {
                return .continue()
            }
            return self.scene(scene, willConnectTo: session, options: options)
            
        case .sceneDidDisconnect:
            return sceneDidDisconnect(scene)
            
        case .sceneDidBecomeActive:
            return sceneDidBecomeActive(scene)
            
        case .sceneWillResignActive:
            return sceneWillResignActive(scene)
            
        case .sceneWillEnterForeground:
            return sceneWillEnterForeground(scene)
            
        case .sceneDidEnterBackground:
            return sceneDidEnterBackground(scene)
            
        case .sceneOpenURLContexts:
            guard let contexts = context.parameters[.urlContexts] as? Set<UIOpenURLContext> else { return .continue() }
            return self.scene(scene, openURLContexts: contexts)
            
        case .sceneContinueUserActivity:
            guard let activity = context.parameters[.userActivity] as? NSUserActivity else { return .continue() }
            return self.scene(scene, continue: activity)
            
        case .sceneDidUpdateUserActivity:
            guard let activity = context.parameters[.userActivity] as? NSUserActivity else { return .continue() }
            return self.scene(scene, didUpdate: activity)
            
        case .sceneDidFailToContinueUserActivity:
            guard let type = context.parameters[.activityType] as? String,
                  let error = context.parameters[.error] as? Error else { return .continue() }
            return self.scene(scene, didFailToContinueUserActivityWithType: type, error: error)
            
        case .sceneStateRestorationActivity:
            return stateRestorationActivity(for: scene)
            
        default:
            return .continue()
        }
    }
}
