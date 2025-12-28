// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义标准生命周期事件（AppDelegate & SceneDelegate）的 Event 常量与参数 Key。

import Foundation

// MARK: - App Lifecycle Event Definitions

public extension OhEvent {
    
    // MARK: - App Launch & Termination
    
    /// 预设阶段：App 启动完成开始（对应 didFinishLaunchingWithOptions 开始）
    static let didFinishLaunchBegin = OhEvent(rawValue: "didFinishLaunchBegin")
    /// 预设阶段：App 启动完成结束（对应 didFinishLaunchingWithOptions 结束）
    static let didFinishLaunchEnd = OhEvent(rawValue: "didFinishLaunchEnd")
    
    /// 预设阶段：App 启动完成（didFinishLaunchingWithOptions）
    /// - Note: 推荐使用 didFinishLaunchBegin/End 进行更细粒度的控制，此 Key 用于统一分发
    static let didFinishLaunching = OhEvent(rawValue: "didFinishLaunching")
    /// 预设阶段：App 将要终止（willTerminate）
    static let willTerminate = OhEvent(rawValue: "willTerminate")
    
    // MARK: - App State Transition
    
    /// 预设阶段：App 进入活动状态（didBecomeActive）
    static let didBecomeActive = OhEvent(rawValue: "didBecomeActive")
    /// 预设阶段：App 将要取消活动状态（willResignActive）
    static let willResignActive = OhEvent(rawValue: "willResignActive")
    /// 预设阶段：App 进入后台（didEnterBackground）
    static let didEnterBackground = OhEvent(rawValue: "didEnterBackground")
    /// 预设阶段：App 将要进入前台（willEnterForeground）
    static let willEnterForeground = OhEvent(rawValue: "willEnterForeground")
    
    // MARK: - System Events (Memory, Time)
    
    /// 收到内存警告 (didReceiveMemoryWarning)
    static let didReceiveMemoryWarning = OhEvent(rawValue: "didReceiveMemoryWarning")
    /// 系统时间发生显著改变 (significantTimeChange)
    static let significantTimeChange = OhEvent(rawValue: "significantTimeChange")
    
    // MARK: - Open URL & User Activity
    
    /// 打开 URL (open url)
    static let openURL = OhEvent(rawValue: "openURL")
    /// 继续用户活动 (continue userActivity)
    static let continueUserActivity = OhEvent(rawValue: "continueUserActivity")
    /// 用户活动更新 (didUpdate userActivity)
    static let didUpdateUserActivity = OhEvent(rawValue: "didUpdateUserActivity")
    /// 用户活动获取失败 (didFailToContinueUserActivity)
    static let didFailToContinueUserActivity = OhEvent(rawValue: "didFailToContinueUserActivity")
    
    // MARK: - Background Tasks & Fetch
    
    /// 后台应用刷新 (performFetchWithCompletionHandler)
    static let performFetch = OhEvent(rawValue: "performFetch")
    /// 后台 URL Session 事件 (handleEventsForBackgroundURLSession)
    static let handleEventsForBackgroundURLSession = OhEvent(rawValue: "handleEventsForBackgroundURLSession")
    
    // MARK: - Notifications
    
    /// 注册远程推送成功 (didRegisterForRemoteNotificationsWithDeviceToken)
    static let didRegisterForRemoteNotifications = OhEvent(rawValue: "didRegisterForRemoteNotifications")
    /// 注册远程推送失败 (didFailToRegisterForRemoteNotificationsWithError)
    static let didFailToRegisterForRemoteNotifications = OhEvent(rawValue: "didFailToRegisterForRemoteNotifications")
    /// 收到远程推送 (didReceiveRemoteNotification)
    static let didReceiveRemoteNotification = OhEvent(rawValue: "didReceiveRemoteNotification")
    
    // MARK: - Scene Session Lifecycle
    
    /// 配置新场景 (configurationForConnecting)
    static let configurationForConnecting = OhEvent(rawValue: "configurationForConnecting")
    /// 丢弃场景 (didDiscardSceneSessions)
    static let didDiscardSceneSessions = OhEvent(rawValue: "didDiscardSceneSessions")
    
    // MARK: - Scene Lifecycle (WindowScene)
    
    /// Scene 连接 (scene:willConnectTo:options:)
    static let sceneWillConnect = OhEvent(rawValue: "sceneWillConnect")
    /// Scene 断开 (sceneDidDisconnect)
    static let sceneDidDisconnect = OhEvent(rawValue: "sceneDidDisconnect")
    /// Scene 激活 (sceneDidBecomeActive)
    static let sceneDidBecomeActive = OhEvent(rawValue: "sceneDidBecomeActive")
    /// Scene 取消激活 (sceneWillResignActive)
    static let sceneWillResignActive = OhEvent(rawValue: "sceneWillResignActive")
    /// Scene 进入前台 (sceneWillEnterForeground)
    static let sceneWillEnterForeground = OhEvent(rawValue: "sceneWillEnterForeground")
    /// Scene 进入后台 (sceneDidEnterBackground)
    static let sceneDidEnterBackground = OhEvent(rawValue: "sceneDidEnterBackground")
    
    // MARK: - Scene Events
    
    /// Scene 打开 URL上下文 (scene:openURLContexts:)
    static let sceneOpenURLContexts = OhEvent(rawValue: "sceneOpenURLContexts")
    /// Scene 继续用户活动 (scene:continue:)
    static let sceneContinueUserActivity = OhEvent(rawValue: "sceneContinueUserActivity")
    /// Scene 更新用户活动 (scene:didUpdate:)
    static let sceneDidUpdateUserActivity = OhEvent(rawValue: "sceneDidUpdateUserActivity")
    /// Scene 用户活动失败 (scene:didFailToContinueUserActivity:error:)
    static let sceneDidFailToContinueUserActivity = OhEvent(rawValue: "sceneDidFailToContinueUserActivity")
    /// Scene 恢复状态 (stateRestorationActivity(for:))
    static let sceneStateRestorationActivity = OhEvent(rawValue: "sceneStateRestorationActivity")
}

// MARK: - Lifecycle Parameter Keys

public extension OhParameterKey {
    
    // MARK: - Common
    static let application = OhParameterKey(rawValue: "application")
    static let launchOptions = OhParameterKey(rawValue: "launchOptions")
    static let error = OhParameterKey(rawValue: "error")
    static let userInfo = OhParameterKey(rawValue: "userInfo")
    static let completionHandler = OhParameterKey(rawValue: "completionHandler")
    
    // MARK: - URL & Activity
    static let url = OhParameterKey(rawValue: "url")
    static let options = OhParameterKey(rawValue: "options")
    static let userActivity = OhParameterKey(rawValue: "userActivity")
    static let restorationHandler = OhParameterKey(rawValue: "restorationHandler")
    static let activityType = OhParameterKey(rawValue: "activityType")
    
    // MARK: - Notifications
    static let deviceToken = OhParameterKey(rawValue: "deviceToken")
    
    // MARK: - Background
    static let identifier = OhParameterKey(rawValue: "identifier")
    
    // MARK: - Scene Session
    static let connectingSceneSession = OhParameterKey(rawValue: "connectingSceneSession")
    static let sceneConnectionOptions = OhParameterKey(rawValue: "sceneConnectionOptions")
    static let sceneSessions = OhParameterKey(rawValue: "sceneSessions")
    
    // MARK: - Window Scene
    static let scene = OhParameterKey(rawValue: "scene")
    static let session = OhParameterKey(rawValue: "session")
    static let connectionOptions = OhParameterKey(rawValue: "connectionOptions")
    static let urlContexts = OhParameterKey(rawValue: "urlContexts")
}
