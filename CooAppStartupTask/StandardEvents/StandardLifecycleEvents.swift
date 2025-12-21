// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义标准生命周期事件（AppDelegate & SceneDelegate）的 Phase 常量与参数 Key。

import Foundation

// MARK: - App Lifecycle Phase Definitions

public extension AppLifecyclePhase {
    
    // MARK: - App Launch & Termination
    
    /// 预设阶段：App 启动完成开始（对应 didFinishLaunchingWithOptions 开始）
    static let didFinishLaunchBegin = AppLifecyclePhase(rawValue: "didFinishLaunchBegin")
    /// 预设阶段：App 启动完成结束（对应 didFinishLaunchingWithOptions 结束）
    static let didFinishLaunchEnd = AppLifecyclePhase(rawValue: "didFinishLaunchEnd")
    /// 预设阶段：App 启动完成（didFinishLaunchingWithOptions）
    /// - Note: 推荐使用 didFinishLaunchBegin/End 进行更细粒度的控制，此 Key 用于统一分发
    static let didFinishLaunching = AppLifecyclePhase(rawValue: "didFinishLaunching")
    /// 预设阶段：App 将要终止（willTerminate）
    static let willTerminate = AppLifecyclePhase(rawValue: "willTerminate")
    
    // MARK: - App State Transition
    
    /// 预设阶段：App 进入活动状态（didBecomeActive）
    static let didBecomeActive = AppLifecyclePhase(rawValue: "didBecomeActive")
    /// 预设阶段：App 将要取消活动状态（willResignActive）
    static let willResignActive = AppLifecyclePhase(rawValue: "willResignActive")
    /// 预设阶段：App 进入后台（didEnterBackground）
    static let didEnterBackground = AppLifecyclePhase(rawValue: "didEnterBackground")
    /// 预设阶段：App 将要进入前台（willEnterForeground）
    static let willEnterForeground = AppLifecyclePhase(rawValue: "willEnterForeground")
    
    // MARK: - System Events (Memory, Time)
    
    /// 收到内存警告 (didReceiveMemoryWarning)
    static let didReceiveMemoryWarning = AppLifecyclePhase(rawValue: "didReceiveMemoryWarning")
    /// 系统时间发生显著改变 (significantTimeChange)
    static let significantTimeChange = AppLifecyclePhase(rawValue: "significantTimeChange")
    
    // MARK: - Open URL & User Activity
    
    /// 打开 URL (open url)
    static let openURL = AppLifecyclePhase(rawValue: "openURL")
    /// 继续用户活动 (continue userActivity)
    static let continueUserActivity = AppLifecyclePhase(rawValue: "continueUserActivity")
    /// 用户活动更新 (didUpdate userActivity)
    static let didUpdateUserActivity = AppLifecyclePhase(rawValue: "didUpdateUserActivity")
    /// 用户活动获取失败 (didFailToContinueUserActivity)
    static let didFailToContinueUserActivity = AppLifecyclePhase(rawValue: "didFailToContinueUserActivity")
    
    // MARK: - Background Tasks & Fetch
    
    /// 后台应用刷新 (performFetchWithCompletionHandler)
    static let performFetch = AppLifecyclePhase(rawValue: "performFetch")
    /// 后台 URL Session 事件 (handleEventsForBackgroundURLSession)
    static let handleEventsForBackgroundURLSession = AppLifecyclePhase(rawValue: "handleEventsForBackgroundURLSession")
    
    // MARK: - Notifications
    
    /// 注册远程推送成功 (didRegisterForRemoteNotificationsWithDeviceToken)
    static let didRegisterForRemoteNotifications = AppLifecyclePhase(rawValue: "didRegisterForRemoteNotifications")
    /// 注册远程推送失败 (didFailToRegisterForRemoteNotificationsWithError)
    static let didFailToRegisterForRemoteNotifications = AppLifecyclePhase(rawValue: "didFailToRegisterForRemoteNotifications")
    /// 收到远程推送 (didReceiveRemoteNotification)
    static let didReceiveRemoteNotification = AppLifecyclePhase(rawValue: "didReceiveRemoteNotification")
    
    // MARK: - Scene Session Lifecycle
    
    /// 配置新场景 (configurationForConnecting)
    static let configurationForConnecting = AppLifecyclePhase(rawValue: "configurationForConnecting")
    /// 丢弃场景 (didDiscardSceneSessions)
    static let didDiscardSceneSessions = AppLifecyclePhase(rawValue: "didDiscardSceneSessions")
    
    // MARK: - Scene Lifecycle (WindowScene)
    
    /// Scene 连接 (scene:willConnectTo:options:)
    static let sceneWillConnect = AppLifecyclePhase(rawValue: "sceneWillConnect")
    /// Scene 断开 (sceneDidDisconnect)
    static let sceneDidDisconnect = AppLifecyclePhase(rawValue: "sceneDidDisconnect")
    /// Scene 激活 (sceneDidBecomeActive)
    static let sceneDidBecomeActive = AppLifecyclePhase(rawValue: "sceneDidBecomeActive")
    /// Scene 取消激活 (sceneWillResignActive)
    static let sceneWillResignActive = AppLifecyclePhase(rawValue: "sceneWillResignActive")
    /// Scene 进入前台 (sceneWillEnterForeground)
    static let sceneWillEnterForeground = AppLifecyclePhase(rawValue: "sceneWillEnterForeground")
    /// Scene 进入后台 (sceneDidEnterBackground)
    static let sceneDidEnterBackground = AppLifecyclePhase(rawValue: "sceneDidEnterBackground")
    
    // MARK: - Scene Events
    
    /// Scene 打开 URL上下文 (scene:openURLContexts:)
    static let sceneOpenURLContexts = AppLifecyclePhase(rawValue: "sceneOpenURLContexts")
    /// Scene 继续用户活动 (scene:continue:)
    static let sceneContinueUserActivity = AppLifecyclePhase(rawValue: "sceneContinueUserActivity")
    /// Scene 更新用户活动 (scene:didUpdate:)
    static let sceneDidUpdateUserActivity = AppLifecyclePhase(rawValue: "sceneDidUpdateUserActivity")
    /// Scene 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    static let sceneDidFailToContinueUserActivity = AppLifecyclePhase(rawValue: "sceneDidFailToContinueUserActivity")
    /// Scene 恢复状态 (stateRestorationActivity(for:))
    static let sceneStateRestorationActivity = AppLifecyclePhase(rawValue: "sceneStateRestorationActivity")
}

// MARK: - Lifecycle Parameter Keys

public extension LifecycleParameterKey {
    
    // MARK: - Common
    static let application = LifecycleParameterKey(rawValue: "application")
    static let launchOptions = LifecycleParameterKey(rawValue: "launchOptions")
    static let error = LifecycleParameterKey(rawValue: "error")
    static let userInfo = LifecycleParameterKey(rawValue: "userInfo")
    static let completionHandler = LifecycleParameterKey(rawValue: "completionHandler")
    
    // MARK: - URL & Activity
    static let url = LifecycleParameterKey(rawValue: "url")
    static let options = LifecycleParameterKey(rawValue: "options")
    static let userActivity = LifecycleParameterKey(rawValue: "userActivity")
    static let restorationHandler = LifecycleParameterKey(rawValue: "restorationHandler")
    static let activityType = LifecycleParameterKey(rawValue: "activityType")
    
    // MARK: - Notifications
    static let deviceToken = LifecycleParameterKey(rawValue: "deviceToken")
    
    // MARK: - Background
    static let identifier = LifecycleParameterKey(rawValue: "identifier")
    
    // MARK: - Scene Session
    static let connectingSceneSession = LifecycleParameterKey(rawValue: "connectingSceneSession")
    static let sceneConnectionOptions = LifecycleParameterKey(rawValue: "sceneConnectionOptions")
    static let sceneSessions = LifecycleParameterKey(rawValue: "sceneSessions")
    
    // MARK: - Window Scene
    static let scene = LifecycleParameterKey(rawValue: "scene")
    static let session = LifecycleParameterKey(rawValue: "session")
    static let connectionOptions = LifecycleParameterKey(rawValue: "connectionOptions")
    static let urlContexts = LifecycleParameterKey(rawValue: "urlContexts")
}
