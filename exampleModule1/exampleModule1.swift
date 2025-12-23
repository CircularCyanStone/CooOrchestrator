//
//  exampleModule1.swift
//  exampleModule1
//
//  Created by 李奇奇 on 2025/12/23.
//  静态库测试案例

import Foundation
import CooOrchestrator
import UIKit

final class ExampleModule1: NSObject, COService, COApplicationObserver, COSceneObserver {

    static func register(in registry: CooOrchestrator.CORegistry<ExampleModule1>) {
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

