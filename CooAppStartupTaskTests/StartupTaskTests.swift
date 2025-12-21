// Copyright © 2025 Coo. All rights reserved.
import XCTest
@testable import CooAppStartupTask

final class AppLifecycleTests: XCTestCase {
    
    static var executionLog: [String] = []
    
    override func setUp() {
        super.setUp()
        Self.executionLog = []
    }
    
    // Mock Tasks
    class MockTaskA: NSObject, AppLifecycleTask {
        static let id = "mock.a"
        static let phase = AppLifecyclePhase.didFinishLaunchBegin
        static let priority = LifecycleTaskPriority(rawValue: 100)
        static let residency = LifecycleTaskRetentionPolicy.destroy
        required override init() {}
        
        func run(context: LifecycleContext) throws -> LifecycleResult {
            AppLifecycleTests.executionLog.append("A")
            context.userInfo.set("A_Data", value: "Hello")
            return .continue()
        }
    }
    
    class MockTaskB: NSObject, AppLifecycleTask {
        static let id = "mock.b"
        static let phase = AppLifecyclePhase.didFinishLaunchBegin
        static let priority = LifecycleTaskPriority(rawValue: 50)
        static let residency = LifecycleTaskRetentionPolicy.destroy
        required override init() {}
        
        func run(context: LifecycleContext) throws -> LifecycleResult {
            AppLifecycleTests.executionLog.append("B")
            // Verify context sharing
            if let data: String = context.userInfo.get("A_Data"), data == "Hello" {
                AppLifecycleTests.executionLog.append("B_Read_Success")
            }
            // Stop here
            return .stop(result: .bool(true))
        }
    }
    
    class MockTaskC: NSObject, AppLifecycleTask {
        static let id = "mock.c"
        static let phase = AppLifecyclePhase.didFinishLaunchBegin
        static let priority = LifecycleTaskPriority(rawValue: 10)
        static let residency = LifecycleTaskRetentionPolicy.destroy
        required override init() {}
        
        func run(context: LifecycleContext) throws -> LifecycleResult {
            AppLifecycleTests.executionLog.append("C")
            return .continue()
        }
    }

    func testResponsibilityChain() {
        let manager = AppLifecycleManager.shared
        
        // Register
        // Note: We use NSStringFromClass to ensure correct runtime lookup
        // In Swift tests, class names are mangled (e.g. CooAppStartupTaskTests.AppLifecycleTests.MockTaskA)
        // Manager uses NSClassFromString which handles this correctly if passed correctly.
        let d1 = TaskDescriptor(className: NSStringFromClass(MockTaskA.self), phase: .didFinishLaunchBegin, priority: MockTaskA.priority)
        let d2 = TaskDescriptor(className: NSStringFromClass(MockTaskB.self), phase: .didFinishLaunchBegin, priority: MockTaskB.priority)
        let d3 = TaskDescriptor(className: NSStringFromClass(MockTaskC.self), phase: .didFinishLaunchBegin, priority: MockTaskC.priority)
        
        manager.register([d1, d2, d3])
        
        // Fire
        let result = manager.fire(.didFinishLaunchBegin)
        
        // 1. Verify Execution Order (A -> B)
        XCTAssertTrue(Self.executionLog.contains("A"), "Task A should run")
        XCTAssertTrue(Self.executionLog.contains("B"), "Task B should run")
        
        // 2. Verify Interception (C should NOT run)
        XCTAssertFalse(Self.executionLog.contains("C"), "Task C should be intercepted")
        
        // 3. Verify Context Sharing
        XCTAssertTrue(Self.executionLog.contains("B_Read_Success"), "Task B should read data from A")
        
        // 4. Verify Return Value
        if case .bool(let val) = result {
            XCTAssertTrue(val)
        } else {
            XCTFail("Should return bool(true)")
        }
    }
    
    func testConcurrency() {
        let manager = AppLifecycleManager.shared
        let d1 = TaskDescriptor(className: NSStringFromClass(MockTaskA.self), phase: .didFinishLaunchEnd)
        manager.register([d1])
        
        let expectation = self.expectation(description: "Concurrent Fire")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = manager.fire(.didFinishLaunchEnd)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
}
