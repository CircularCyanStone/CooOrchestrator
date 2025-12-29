//
//  OhSceneDelegate.swift
//  CooOrchestrator
//
//  Created by 李奇奇 on 2025/12/29.
//

import UIKit

/// 默认的 SceneDelegate 实现，提供标准 Scene 生命周期事件的转发。
/// - 开发者可以继承此类，并根据需要重写相关方法。
/// - 注意：此类仅转发 `OhSceneDelegateEvents` 中定义的标准系统事件。
open class OhSceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    open var window: UIWindow?
    
    // MARK: - Scene Life Cycle
    
    open func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let shouldFirePhases: Bool = window == nil
        if shouldFirePhases {
            Orchestrator.fire(.appStart)
        }
        let params: [OhParameterKey: Any] = [
            .scene: scene,
            .session: session,
            .connectionOptions: connectionOptions
        ]
        Orchestrator.fire(.sceneWillConnect, parameters: params)
        if shouldFirePhases {
            Orchestrator.fire(.appReady)
        }
    }
    
    open func sceneDidDisconnect(_ scene: UIScene) {
        Orchestrator.fire(.sceneDidDisconnect, parameters: [.scene: scene])
    }
    
    open func sceneDidBecomeActive(_ scene: UIScene) {
        Orchestrator.fire(.sceneDidBecomeActive, parameters: [.scene: scene])
    }
    
    open func sceneWillResignActive(_ scene: UIScene) {
        Orchestrator.fire(.sceneWillResignActive, parameters: [.scene: scene])
    }
    
    open func sceneWillEnterForeground(_ scene: UIScene) {
        Orchestrator.fire(.sceneWillEnterForeground, parameters: [.scene: scene])
    }
    
    open func sceneDidEnterBackground(_ scene: UIScene) {
        Orchestrator.fire(.sceneDidEnterBackground, parameters: [.scene: scene])
    }
    
    // MARK: - Scene Events
    
    open func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let params: [OhParameterKey: Any] = [
            .scene: scene,
            .urlContexts: URLContexts
        ]
        Orchestrator.fire(.sceneOpenURLContexts, parameters: params)
    }
    
    open func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        let params: [OhParameterKey: Any] = [
            .scene: scene,
            .userActivity: userActivity
        ]
        Orchestrator.fire(.sceneContinueUserActivity, parameters: params)
    }
    
    open func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        let params: [OhParameterKey: Any] = [
            .scene: scene,
            .userActivity: userActivity
        ]
        Orchestrator.fire(.sceneDidUpdateUserActivity, parameters: params)
    }
    
    open func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        let params: [OhParameterKey: Any] = [
            .scene: scene,
            .activityType: userActivityType,
            .error: error
        ]
        Orchestrator.fire(.sceneDidFailToContinueUserActivity, parameters: params)
    }
    
    open func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let params: [OhParameterKey: Any] = [.scene: scene]
        return Orchestrator.fire(.sceneStateRestorationActivity, parameters: params)
    }
}
