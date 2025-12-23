//
//  AppDelegate.swift
//  example
//
//  Created by 李奇奇 on 2025/12/19.
//

import UIKit
import CooOrchestrator
import exampleModule1
import DynamicModule2

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. 显式启动解析（推荐）
        COrchestrator.shared.resolve()
        
        // 2. 触发启动事件
        COrchestrator.shared.fire(
            .didFinishLaunching,
            parameters: [
                .application: application,
                .launchOptions: launchOptions as Any
            ]
        )
        COrchestrator.shared.fire(.didFinishLaunchBegin, parameters: [
            .application: application,
            .launchOptions : launchOptions as Any
        ])
        
        COrchestrator.shared.fire(.didFinishLaunchEnd, parameters: [
            .application: application,
            .launchOptions : launchOptions as Any
        ])
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
