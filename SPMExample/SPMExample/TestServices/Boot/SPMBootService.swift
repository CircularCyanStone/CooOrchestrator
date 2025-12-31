//
//  SPMBootService.swift
//  SPMExample
//
//  Created by 李奇奇 on 2025/12/31.
//

import UIKit
import CooOrchestrator

@OrchService()
final class SPMBootService: OhService, OhSceneObserver {
    static func register(in registry: CooOrchestrator.OhRegistry<SPMBootService>) {
        addApplication(.didFinishLaunching, in: registry)
        addScene(.appReady, in: registry)
        addScene(.sceneWillConnect, in: registry)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions, context: OhContext) -> OhResult {
        guard let windowScene = scene as? UIWindowScene else {
            return .stop(result: .void)
        }
        let sceneDelegate = context.source as? OhSceneDelegate
        sceneDelegate?.window = UIWindow(windowScene: windowScene)
        sceneDelegate?.window?.rootViewController = ViewController()
        sceneDelegate?.window?.makeKeyAndVisible()
        return .stop()
    }

}
extension SPMBootService: OhApplicationObserver {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?, context: OhContext) -> OhResult {
        .continue
    }
}
