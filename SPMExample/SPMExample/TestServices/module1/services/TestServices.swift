//
//  TestServices.swift
//  SPMExample
//
//  Created by Coo on 2025/12/26.
//

import Foundation
import CooOrchestrator

// MARK: - 模块内服务 (通过 Module 注册)

// 服务 A
final class TestServiceA: OhService {
    required init() {}
    
    static func register(in registry: OhRegistry<TestServiceA>) {
        // 注册一些事件...
        registry.add(.didFinishLaunching) { s, c in
            print("TestServiceA didFinishLaunching")
        }
        
        registry.add(.appReady) { s, c in
            print("TestServiceA appReady")
        }
        print("TestServiceA registered")
    }
}

// 服务 B
@OrchService()
final class TestServiceB: OhService {
    required init() {}
    
    
    static func register(in registry: OhRegistry<TestServiceB>) {
        registry.add(.didFinishLaunching) { s, c in
            print("TestServiceB didFinishLaunching")
        }
        
        registry.add(.appReady) { s, c in
            print("TestServiceB appReady")
        }
        print("TestServiceB registered")
    }
    
    
}

// MARK: - 测试模块 (使用 @OrchModule 注册)

// 这个模块负责加载 ServiceA 和 ServiceB
@OrchModule()
final class TestModuleSource: OhModuleServicesProvider {
    
    required init() {}
    
    func provideServices() -> [OhServiceDefinition] {
        return [
            .service(TestServiceA.self),
            .service(TestServiceB.self)
        ]
    }
}

// MARK: - 独立服务 (使用 @OrchService 直接注册)

// 服务 C
@OrchService()
final class TestServiceC: OhService {
    required init() {}
    
    static func register(in registry: OhRegistry<TestServiceC>) {
        registry.add(.didFinishLaunching) { s, c in
            print("TestServiceC didFinishLaunching")
        }
        
        registry.add(.appReady) { s, c in
            print("TestServiceC appReady")
        }
        print("TestServiceC registered via Macro")
    }
}

// 服务 D
@OrchService("SPMExample")
final class TestServiceD: OhService {
    required init() {}
    
    static func register(in registry: OhRegistry<TestServiceD>) {
        registry.add(.didFinishLaunching) { s, c in
            print("TestServiceD didFinishLaunching")
        }
        
        registry.add(.appReady) { s, c in
            print("TestServiceD appReady")
        }
        print("TestServiceD registered via Macro")
    }
}


@OrchModule()
final class TestServiceF {
    required init() {}
}

extension TestServiceF: OhModuleServicesProvider {
    func provideServices() -> [CooOrchestrator.OhServiceDefinition] {
        return [
            .service(TestServiceA.self),
            .service(TestServiceB.self)
        ]
    }
}
