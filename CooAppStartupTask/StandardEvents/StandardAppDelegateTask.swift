// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：提供预置系统事件的便捷协议与扩展，简化常用生命周期方法的接入。

import Foundation
import UIKit

/// 标准 AppDelegate 生命周期任务协议
/// - 开发者可以选择遵守此协议，直接实现对应的生命周期方法，而无需在 `run` 方法中手动 switch phase。
/// - 所有方法均返回 `LifecycleResult`，支持责任链控制（如阻断后续任务）。
public protocol StandardAppDelegateTask: AppLifecycleTask {
    
    // MARK: - App Life Cycle
    
    /// App 启动完成 (didFinishLaunchingWithOptions)
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> LifecycleResult
    
    /// App 进入活动状态 (didBecomeActive)
    func applicationDidBecomeActive(_ application: UIApplication) -> LifecycleResult
    
    /// App 将要取消活动状态 (willResignActive)
    func applicationWillResignActive(_ application: UIApplication) -> LifecycleResult
    
    /// App 进入后台 (didEnterBackground)
    func applicationDidEnterBackground(_ application: UIApplication) -> LifecycleResult
    
    /// App 将要进入前台 (willEnterForeground)
    func applicationWillEnterForeground(_ application: UIApplication) -> LifecycleResult
    
    /// App 将要终止 (willTerminate)
    func applicationWillTerminate(_ application: UIApplication) -> LifecycleResult
    
    // MARK: - System Events (Memory, Time)
    
    /// 收到内存警告 (didReceiveMemoryWarning)
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) -> LifecycleResult
    
    /// 系统时间发生显著改变 (significantTimeChange)
    func applicationSignificantTimeChange(_ application: UIApplication) -> LifecycleResult
    
    // MARK: - Open URL & User Activity
    
    /// 打开 URL (open url)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> LifecycleResult
    
    /// 继续用户活动 (continue userActivity)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> LifecycleResult
    
    /// 用户活动更新 (didUpdate userActivity)
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) -> LifecycleResult
    
    /// 用户活动获取失败 (didFailToContinueUserActivity)
    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> LifecycleResult
    
    // MARK: - Background Tasks & Fetch
    
    /// 后台应用刷新 (performFetchWithCompletionHandler)
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> LifecycleResult
    
    /// 后台 URL Session 事件 (handleEventsForBackgroundURLSession)
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) -> LifecycleResult
    
    // MARK: - Notifications
    
    /// 注册远程推送成功 (didRegisterForRemoteNotificationsWithDeviceToken)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) -> LifecycleResult
    
    /// 注册远程推送失败 (didFailToRegisterForRemoteNotificationsWithError)
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) -> LifecycleResult
    
    /// 收到远程推送 (didReceiveRemoteNotification)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> LifecycleResult
    
    // MARK: - Scene
    
    /// 配置新场景 (configurationForConnecting)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> LifecycleResult
    
    /// 丢弃场景 (didDiscardSceneSessions)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) -> LifecycleResult
}

// MARK: - Default Implementation & Routing

public extension StandardAppDelegateTask {
    
    // MARK: Default Implementations (Return .continue())
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> LifecycleResult { .continue() }
    func applicationDidBecomeActive(_ application: UIApplication) -> LifecycleResult { .continue() }
    func applicationWillResignActive(_ application: UIApplication) -> LifecycleResult { .continue() }
    func applicationDidEnterBackground(_ application: UIApplication) -> LifecycleResult { .continue() }
    func applicationWillEnterForeground(_ application: UIApplication) -> LifecycleResult { .continue() }
    func applicationWillTerminate(_ application: UIApplication) -> LifecycleResult { .continue() }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) -> LifecycleResult { .continue() }
    func applicationSignificantTimeChange(_ application: UIApplication) -> LifecycleResult { .continue() }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) -> LifecycleResult { .continue() }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) -> LifecycleResult { .continue() }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> LifecycleResult { .continue() }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> LifecycleResult { .continue() }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) -> LifecycleResult { .continue() }
    
    // MARK: - Auto Routing
    
    func run(context: LifecycleContext) throws -> LifecycleResult {
        // 尝试从参数中获取 UIApplication
        // 注意：由于 run 方法非隔离，无法直接访问 MainActor 的 UIApplication.shared，必须通过参数传递
        guard let app = context.parameters[.application] as? UIApplication else {
            // 如果缺少 application 参数，无法执行后续逻辑，直接跳过
            return .continue()
        }
        
        switch context.phase {
        case .didFinishLaunchBegin, .didFinishLaunchEnd, .didFinishLaunching:
            let options = context.parameters[.launchOptions] as? [UIApplication.LaunchOptionsKey: Any]
            return application(app, didFinishLaunchingWithOptions: options)
            
        case .didBecomeActive:
            return applicationDidBecomeActive(app)
            
        case .willResignActive:
            return applicationWillResignActive(app)
            
        case .didEnterBackground:
            return applicationDidEnterBackground(app)
            
        case .willEnterForeground:
            return applicationWillEnterForeground(app)
            
        case .willTerminate:
            return applicationWillTerminate(app)
            
        case .didReceiveMemoryWarning:
            return applicationDidReceiveMemoryWarning(app)
            
        case .significantTimeChange:
            return applicationSignificantTimeChange(app)
            
        case .openURL:
            guard let url = context.parameters[.url] as? URL,
                  let options = context.parameters[.options] as? [UIApplication.OpenURLOptionsKey : Any] else {
                return .continue()
            }
            return application(app, open: url, options: options)
            
        case .continueUserActivity:
            guard let activity = context.parameters[.userActivity] as? NSUserActivity,
                  let handler = context.parameters[.restorationHandler] as? ([UIUserActivityRestoring]?) -> Void else {
                return .continue()
            }
            return application(app, continue: activity, restorationHandler: handler)
            
        case .didUpdateUserActivity:
            guard let activity = context.parameters[.userActivity] as? NSUserActivity else { return .continue() }
            return application(app, didUpdate: activity)
            
        case .didFailToContinueUserActivity:
            guard let type = context.parameters[.activityType] as? String,
                  let error = context.parameters[.error] as? Error else { return .continue() }
            return application(app, didFailToContinueUserActivityWithType: type, error: error)
            
        case .performFetch:
            guard let handler = context.parameters[.completionHandler] as? (UIBackgroundFetchResult) -> Void else { return .continue() }
            return application(app, performFetchWithCompletionHandler: handler)
            
        case .handleEventsForBackgroundURLSession:
            guard let identifier = context.parameters[.identifier] as? String,
                  let handler = context.parameters[.completionHandler] as? () -> Void else { return .continue() }
            return application(app, handleEventsForBackgroundURLSession: identifier, completionHandler: handler)
            
        case .didRegisterForRemoteNotifications:
            guard let token = context.parameters[.deviceToken] as? Data else { return .continue() }
            return application(app, didRegisterForRemoteNotificationsWithDeviceToken: token)
            
        case .didFailToRegisterForRemoteNotifications:
            guard let error = context.parameters[.error] as? Error else { return .continue() }
            return application(app, didFailToRegisterForRemoteNotificationsWithError: error)
            
        case .didReceiveRemoteNotification:
            guard let userInfo = context.parameters[.userInfo] as? [AnyHashable : Any],
                  let handler = context.parameters[.completionHandler] as? (UIBackgroundFetchResult) -> Void else {
                return .continue()
            }
            return application(app, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: handler)
            
        case .configurationForConnecting:
            guard let session = context.parameters[.connectingSceneSession] as? UISceneSession,
                  let options = context.parameters[.sceneConnectionOptions] as? UIScene.ConnectionOptions else {
                return .continue()
            }
            return application(app, configurationForConnecting: session, options: options)
            
        case .didDiscardSceneSessions:
            guard let sessions = context.parameters[.sceneSessions] as? Set<UISceneSession> else { return .continue() }
            return application(app, didDiscardSceneSessions: sessions)
            
        default:
            return .continue()
        }
    }
}
