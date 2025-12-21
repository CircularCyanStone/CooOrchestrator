// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义生命周期任务的基础枚举与结构体类型，包括执行时机、优先级与驻留策略。

import Foundation

/// 应用生命周期阶段，任务执行时机（结构体封装，支持自定义扩展）
public struct AppLifecyclePhase: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// 生命周期事件参数键名
public struct LifecycleParameterKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

/// 任务优先级包装（可比较、可发送）
public struct LifecycleTaskPriority: RawRepresentable, Comparable, Sendable {
    /// 底层优先级数值（越大越先执行）
    public let rawValue: Int
    /// 以原始数值构造优先级
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static func < (lhs: LifecycleTaskPriority, rhs: LifecycleTaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// 任务执行后的持有策略（字符串原始值，便于清单直接映射）
public enum LifecycleTaskRetentionPolicy: String, Sendable {
    /// 执行结束即释放，不被管理器持有
    case destroy
    /// 执行后被管理器以 `id` 持有，直至进程结束或手动清理
    case hold
}
