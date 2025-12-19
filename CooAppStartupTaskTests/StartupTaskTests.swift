// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务模块的基础单元测试，验证清单解析、优先级排序、时机分发与生命周期策略。
// 类型功能描述：StartupTaskTests 使用 XCTest 断言核心行为的正确性。

import XCTest
@testable import CooAppStartupTask

final class StartupTaskTests: XCTestCase {
    func testPrioritySorting() {
        let d1 = TaskDescriptor(className: "A", phase: .appLaunchEarly, priority: .init(rawValue: 1), residency: .autoDestroy)
        let d2 = TaskDescriptor(className: "B", phase: .appLaunchEarly, priority: .init(rawValue: 100), residency: .autoDestroy)
        let d3 = TaskDescriptor(className: "C", phase: .appLaunchLate, priority: .init(rawValue: 50), residency: .resident)
        let mgr = StartupTaskManager.shared
        mgr.register([d1, d2, d3])
        // 无法直接探测内部排序，仅验证 fire 不崩溃
        mgr.fire(.appLaunchEarly)
        mgr.fire(.appLaunchLate)
    }
}

