#if canImport(UIKit)
// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：提供 UIWindowSceneDelegate 预置事件的便捷协议与扩展。

import Foundation
import UIKit

/// 标准 SceneDelegate 生命周期观察者协议
/// - 适用于 iOS 13+ 的多窗口场景
/// - 开发者可以选择遵守此协议，直接实现对应的生命周期方法
/// - 注意：此协议不继承 `OhService`，需显式遵守 `OhService` 协议并手动注册感兴趣的事件。
public protocol OhSceneObserver: Sendable {
    
    // MARK: - Scene Life Cycle
    
    /// Scene 连接 (scene:willConnectTo:options:)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> OhResult
    
    /// Scene 断开 (sceneDidDisconnect)
    func sceneDidDisconnect(_ scene: UIScene) -> OhResult
    
    /// Scene 激活 (sceneDidBecomeActive)
    func sceneDidBecomeActive(_ scene: UIScene) -> OhResult
    
    /// Scene 取消激活 (sceneWillResignActive)
    func sceneWillResignActive(_ scene: UIScene) -> OhResult
    
    /// Scene 进入前台 (sceneWillEnterForeground)
    func sceneWillEnterForeground(_ scene: UIScene) -> OhResult
    
    /// Scene 进入后台 (sceneDidEnterBackground)
    func sceneDidEnterBackground(_ scene: UIScene) -> OhResult
    
    // MARK: - Scene Events
    
    /// 打开 URL 上下文 (scene:openURLContexts:)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> OhResult
    
    /// 继续用户活动 (scene:continue:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> OhResult
    
    /// 更新用户活动 (scene:didUpdate:)
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> OhResult
    
    /// 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> OhResult
    
    /// 状态恢复 (stateRestorationActivity(for:))
    func stateRestorationActivity(for scene: UIScene) -> OhResult
}

// MARK: - Default Implementation & Routing

public extension OhSceneObserver {
    
    // MARK: Default Implementations
    static func addScene<Service: OhService & OhSceneObserver>(_ event: OhEvent, in registry: OhRegistry<Service>) {
        registry.add(event) { s, c in
            try s.dispatchSceneEvent(c)
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> OhResult { .continue() }
    func sceneDidDisconnect(_ scene: UIScene) -> OhResult { .continue() }
    func sceneDidBecomeActive(_ scene: UIScene) -> OhResult { .continue() }
    func sceneWillResignActive(_ scene: UIScene) -> OhResult { .continue() }
    func sceneWillEnterForeground(_ scene: UIScene) -> OhResult { .continue() }
    func sceneDidEnterBackground(_ scene: UIScene) -> OhResult { .continue() }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> OhResult { .continue() }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> OhResult { .continue() }
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) -> OhResult { .continue() }
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> OhResult { .continue() }
    func stateRestorationActivity(for scene: UIScene) -> OhResult { .continue() }
    
    // MARK: - Internal Dispatcher
    
    /// 将通用上下文分发到具体的协议方法
    /// - Parameter context: 服务上下文
    /// - Returns: 执行结果
    @discardableResult
    func dispatchSceneEvent(_ context: OhContext) throws -> OhResult {
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
#endif
