// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：提供 UIWindowSceneDelegate 预置事件的便捷协议与扩展。

import Foundation
import UIKit

/// 标准 SceneDelegate 生命周期任务协议
/// - 适用于 iOS 13+ 的多窗口场景
/// - 开发者可以选择遵守此协议，直接实现对应的生命周期方法
public protocol StandardSceneDelegateTask: COService {
    
    // MARK: - Scene Life Cycle
    
    /// Scene 连接 (scene:willConnectTo:options:)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> COResult
    
    /// Scene 断开 (sceneDidDisconnect)
    func sceneDidDisconnect(_ scene: UIScene) -> COResult
    
    /// Scene 激活 (sceneDidBecomeActive)
    func sceneDidBecomeActive(_ scene: UIScene) -> COResult
    
    /// Scene 取消激活 (sceneWillResignActive)
    func sceneWillResignActive(_ scene: UIScene) -> COResult
    
    /// Scene 进入前台 (sceneWillEnterForeground)
    func sceneWillEnterForeground(_ scene: UIScene) -> COResult
    
    /// Scene 进入后台 (sceneDidEnterBackground)
    func sceneDidEnterBackground(_ scene: UIScene) -> COResult
    
    // MARK: - Scene Events
    
    /// 打开 URL 上下文 (scene:openURLContexts:)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> COResult
    
    /// 继续用户活动 (scene:continue:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> COResult
    
    /// 更新用户活动 (scene:didUpdate:)
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> COResult
    
    /// 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> COResult
    
    /// 状态恢复 (stateRestorationActivity(for:))
    func stateRestorationActivity(for scene: UIScene) -> COResult
}

// MARK: - Default Implementation & Routing

public extension StandardSceneDelegateTask {
    
    // MARK: - Automatic Registry
    
    static func register(in registry: CORegistry<Self>) {
        // Lifecycle
        registry.add(.sceneWillConnect) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneDidDisconnect) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneDidBecomeActive) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneWillResignActive) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneWillEnterForeground) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneDidEnterBackground) { s, c in try s.dispatchSceneEvent(c) }
        
        // Events
        registry.add(.sceneOpenURLContexts) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneContinueUserActivity) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneDidUpdateUserActivity) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneDidFailToContinueUserActivity) { s, c in try s.dispatchSceneEvent(c) }
        registry.add(.sceneStateRestorationActivity) { s, c in try s.dispatchSceneEvent(c) }
    }
    
    // MARK: Default Implementations
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> COResult { .continue() }
    func sceneDidDisconnect(_ scene: UIScene) -> COResult { .continue() }
    func sceneDidBecomeActive(_ scene: UIScene) -> COResult { .continue() }
    func sceneWillResignActive(_ scene: UIScene) -> COResult { .continue() }
    func sceneWillEnterForeground(_ scene: UIScene) -> COResult { .continue() }
    func sceneDidEnterBackground(_ scene: UIScene) -> COResult { .continue() }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> COResult { .continue() }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> COResult { .continue() }
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> COResult { .continue() }
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> COResult { .continue() }
    func stateRestorationActivity(for scene: UIScene) -> COResult { .continue() }
    
    // MARK: - Internal Dispatcher
    
    func dispatchSceneEvent(_ context: COContext) throws -> COResult {
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
