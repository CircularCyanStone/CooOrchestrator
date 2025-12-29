//
//  AppDelegate.swift
//  SPMExample
//
//  Created by 李奇奇 on 2025/12/27.
//

import UIKit
import CooOrchestrator

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1. 启动服务编排
        Orchestrator.resolve(sources: [OhObjcSectionScanner(), OhSwiftSectionScanner()])
        
        let params: [OhParameterKey: Any] = [
            .application: application,
            .launchOptions: launchOptions ?? [:]
        ]
        
        // 2. 触发启动开始
        Orchestrator.fire(.appStart, parameters: params)
        
        // 3. 触发核心启动逻辑 (RootWindow, 核心SDK等 - 对应 OhApplicationObserver)
        Orchestrator.fire(.didFinishLaunching, parameters: params)
        
        // 4. 触发启动结束
        Orchestrator.fire(.appReady, parameters: params)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return connectingSceneSession.configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        print("==========")
    }


}

