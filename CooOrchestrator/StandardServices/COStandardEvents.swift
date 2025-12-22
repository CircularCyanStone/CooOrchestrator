// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义标准生命周期事件（AppDelegate & SceneDelegate）的 Event 常量与参数 Key。

import Foundation

// MARK: - App Lifecycle Event Definitions

public extension COEvent {
    
    // MARK: - App Launch & Termination
    
    /// 预设阶段：App 启动完成开始（对应 didFinishLaunchingWithOptions 开始）
    static let didFinishLaunchBegin = COEvent(rawValue: "didFinishLaunchBegin")
    /// 预设阶段：App 启动完成结束（对应 didFinishLaunchingWithOptions 结束）
    static let didFinishLaunchEnd = COEvent(rawValue: "didFinishLaunchEnd")
    /// 预设阶段：App 启动完成（didFinishLaunchingWithOptions）
    /// - Note: 推荐使用 didFinishLaunchBegin/End 进行更细粒度的控制，此 Key 用于统一分发
    static let didFinishLaunching = COEvent(rawValue: "didFinishLaunching")
    /// 预设阶段：App 将要终止（willTerminate）
    static let willTerminate = COEvent(rawValue: "willTerminate")
    
    // MARK: - App State Transition
    
    /// 预设阶段：App 进入活动状态（didBecomeActive）
    static let didBecomeActive = COEvent(rawValue: "didBecomeActive")
    /// 预设阶段：App 将要取消活动状态（willResignActive）
    static let willResignActive = COEvent(rawValue: "willResignActive")
    /// 预设阶段：App 进入后台（didEnterBackground）
    static let didEnterBackground = COEvent(rawValue: "didEnterBackground")
    /// 预设阶段：App 将要进入前台（willEnterForeground）
    static let willEnterForeground = COEvent(rawValue: "willEnterForeground")
    
    // MARK: - System Events (Memory, Time)
    
    /// 收到内存警告 (didReceiveMemoryWarning)
    static let didReceiveMemoryWarning = COEvent(rawValue: "didReceiveMemoryWarning")
    /// 系统时间发生显著改变 (significantTimeChange)
    static let significantTimeChange = COEvent(rawValue: "significantTimeChange")
    
    // MARK: - Open URL & User Activity
    
    /// 打开 URL (open url)
    static let openURL = COEvent(rawValue: "openURL")
    /// 继续用户活动 (continue userActivity)
    static let continueUserActivity = COEvent(rawValue: "continueUserActivity")
    /// 用户活动更新 (didUpdate userActivity)
    static let didUpdateUserActivity = COEvent(rawValue: "didUpdateUserActivity")
    /// 用户活动获取失败 (didFailToContinueUserActivity)
    static let didFailToContinueUserActivity = COEvent(rawValue: "didFailToContinueUserActivity")
    
    // MARK: - Background Tasks & Fetch
    
    /// 后台应用刷新 (performFetchWithCompletionHandler)
    static let performFetch = COEvent(rawValue: "performFetch")
    /// 后台 URL Session 事件 (handleEventsForBackgroundURLSession)
    static let handleEventsForBackgroundURLSession = COEvent(rawValue: "handleEventsForBackgroundURLSession")
    
    // MARK: - Notifications
    
    /// 注册远程推送成功 (didRegisterForRemoteNotificationsWithDeviceToken)
    static let didRegisterForRemoteNotifications = COEvent(rawValue: "didRegisterForRemoteNotifications")
    /// 注册远程推送失败 (didFailToRegisterForRemoteNotificationsWithError)
    static let didFailToRegisterForRemoteNotifications = COEvent(rawValue: "didFailToRegisterForRemoteNotifications")
    /// 收到远程推送 (didReceiveRemoteNotification)
    static let didReceiveRemoteNotification = COEvent(rawValue: "didReceiveRemoteNotification")
    
    // MARK: - Scene Session Lifecycle
    
    /// 配置新场景 (configurationForConnecting)
    static let configurationForConnecting = COEvent(rawValue: "configurationForConnecting")
    /// 丢弃场景 (didDiscardSceneSessions)
    static let didDiscardSceneSessions = COEvent(rawValue: "didDiscardSceneSessions")
    
    // MARK: - Scene Lifecycle (WindowScene)
    
    /// Scene 连接 (scene:willConnectTo:options:)
    static let sceneWillConnect = COEvent(rawValue: "sceneWillConnect")
    /// Scene 断开 (sceneDidDisconnect)
    static let sceneDidDisconnect = COEvent(rawValue: "sceneDidDisconnect")
    /// Scene 激活 (sceneDidBecomeActive)
    static let sceneDidBecomeActive = COEvent(rawValue: "sceneDidBecomeActive")
    /// Scene 取消激活 (sceneWillResignActive)
    static let sceneWillResignActive = COEvent(rawValue: "sceneWillResignActive")
    /// Scene 进入前台 (sceneWillEnterForeground)
    static let sceneWillEnterForeground = COEvent(rawValue: "sceneWillEnterForeground")
    /// Scene 进入后台 (sceneDidEnterBackground)
    static let sceneDidEnterBackground = COEvent(rawValue: "sceneDidEnterBackground")
    
    // MARK: - Scene Events
    
    /// Scene 打开 URL上下文 (scene:openURLContexts:)
    static let sceneOpenURLContexts = COEvent(rawValue: "sceneOpenURLContexts")
    /// Scene 继续用户活动 (scene:continue:)
    static let sceneContinueUserActivity = COEvent(rawValue: "sceneContinueUserActivity")
    /// Scene 更新用户活动 (scene:didUpdate:)
    static let sceneDidUpdateUserActivity = COEvent(rawValue: "sceneDidUpdateUserActivity")
    /// Scene 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    static let sceneDidFailToContinueUserActivity = COEvent(rawValue: "sceneDidFailToContinueUserActivity")
    /// Scene 恢复状态 (stateRestorationActivity(for:))
    static let sceneStateRestorationActivity = COEvent(rawValue: "sceneStateRestorationActivity")
}

// MARK: - Lifecycle Parameter Keys

public extension COParameterKey {
    
    // MARK: - Common
    static let application = COParameterKey(rawValue: "application")
    static let launchOptions = COParameterKey(rawValue: "launchOptions")
    static let error = COParameterKey(rawValue: "error")
    static let userInfo = COParameterKey(rawValue: "userInfo")
    static let completionHandler = COParameterKey(rawValue: "completionHandler")
    
    // MARK: - URL & Activity
    static let url = COParameterKey(rawValue: "url")
    static let options = COParameterKey(rawValue: "options")
    static let userActivity = COParameterKey(rawValue: "userActivity")
    static let restorationHandler = COParameterKey(rawValue: "restorationHandler")
    static let activityType = COParameterKey(rawValue: "activityType")
    
    // MARK: - Notifications
    static let deviceToken = COParameterKey(rawValue: "deviceToken")
    
    // MARK: - Background
    static let identifier = COParameterKey(rawValue: "identifier")
    
    // MARK: - Scene Session
    static let connectingSceneSession = COParameterKey(rawValue: "connectingSceneSession")
    static let sceneConnectionOptions = COParameterKey(rawValue: "sceneConnectionOptions")
    static let sceneSessions = COParameterKey(rawValue: "sceneSessions")
    
    // MARK: - Window Scene
    static let scene = COParameterKey(rawValue: "scene")
    static let session = COParameterKey(rawValue: "session")
    static let connectionOptions = COParameterKey(rawValue: "connectionOptions")
    static let urlContexts = COParameterKey(rawValue: "urlContexts")
}
