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
        OhLogger.log("TestServiceA registered")
    }
}

// 服务 B
@OrchService()
final class TestServiceB: OhService {
    required init() {}
    
    
    static func register(in registry: OhRegistry<TestServiceB>) {
        OhLogger.log("TestServiceB registered")
    }
    
    
}

// MARK: - 测试模块 (使用 @OrchModule 注册)

// 这个模块负责加载 ServiceA 和 ServiceB
@OrchModule()
final class TestModuleSource: OhServiceSource {
    required init() {}
    
    func load() -> [OhServiceDefinition] {
        return [
            .service(TestServiceA.self),
            .service(TestServiceB.self)
        ]
    }
}

// MARK: - 独立服务 (使用 @OrchService 直接注册)

// 服务 C
@OrchModule()
final class TestServiceC: OhService {
    required init() {}
    
    static func register(in registry: OhRegistry<TestServiceC>) {
        OhLogger.log("TestServiceC registered via Macro")
    }
}

// 服务 D
@OrchService("SPMExample")
final class TestServiceD: OhService {
    required init() {}
    
    static func register(in registry: OhRegistry<TestServiceD>) {
        OhLogger.log("TestServiceD registered via Macro")
    }
}
