//
//  DynamicModule2.swift
//  DynamicModule2
//
//  Created by 李奇奇 on 2025/12/23.
//  动态库测试案例

import Foundation
import CooOrchestrator
import UIKit

final class DynamicModule2: NSObject, COService, COApplicationObserver, COSceneObserver {

    static func register(in registry: CooOrchestrator.CORegistry<DynamicModule2>) {
        addScene(.sceneWillConnect, in: registry)
        addApplication(.didFinishLaunching, in: registry)
    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> COResult {
        print("====")
        return .continue()
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) -> COResult {
        print("====")
        return .continue()
    }
    
}

