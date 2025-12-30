//
//  AppDelegate.swift
//  example
//
//  Created by 李奇奇 on 2025/12/19.
//

import CooOrchestrator
import DynamicModule2
import UIKit
import exampleModule1

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        // 1. 显式启动解析（推荐）
        Orchestrator.resolve(sources: [OhManifestScanner(), OhModuleScanner(), OhObjcSectionScanner()])

        let params: [OhParameterKey: Any] = [
            .application: application,
            .launchOptions: launchOptions ?? [:],
        ]
        // 3. 触发核心启动逻辑 (RootWindow, 核心SDK等 - 对应 OhApplicationObserver)
        Orchestrator.fire(.didFinishLaunching, parameters: params)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
