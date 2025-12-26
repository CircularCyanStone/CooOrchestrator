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
final class TestServiceA: COService {
    required init() {}
    
    static func register(in registry: CORegistry<TestServiceA>) {
        // 注册一些事件...
        COLogger.log("TestServiceA registered")
    }
}

// 服务 B
final class TestServiceB: COService {
    required init() {}
    
    
    static func register(in registry: CORegistry<TestServiceB>) {
        COLogger.log("TestServiceB registered")
    }
    
    
}

// MARK: - 测试模块 (使用 @OrchModule 注册)

// 这个模块负责加载 ServiceA 和 ServiceB
@OrchModule("SPMExample")
final class TestModuleSource: COServiceSource {
    required init() {}
    
    func load() -> [COServiceDefinition] {
        return [
            .service(TestServiceA.self),
            .service(TestServiceB.self)
        ]
    }
}

// MARK: - 独立服务 (使用 @OrchService 直接注册)

// 服务 C
@OrchService("SPMExample")
final class TestServiceC: COService {
    required init() {}
    
    static func register(in registry: CORegistry<TestServiceC>) {
        COLogger.log("TestServiceC registered via Macro")
    }
}

// 服务 D
@OrchService("SPMExample")
final class TestServiceD: COService {
    required init() {}
    
    static func register(in registry: CORegistry<TestServiceD>) {
        COLogger.log("TestServiceD registered via Macro")
    }
}
