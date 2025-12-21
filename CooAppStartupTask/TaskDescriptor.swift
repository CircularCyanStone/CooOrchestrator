// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义任务描述符，用于从清单文件或宏生成任务元数据，支持延迟实例化。

import Foundation

/// 任务描述符（来自 Manifest 或未来宏生成），用于延迟实例化任务
public struct TaskDescriptor: Sendable {
    /// 任务类名（建议包含模块前缀，如 `Module.Class`）
    public let className: String
    /// 执行时机（可选，未提供则使用类型静态默认值）
    public let phase: AppLifecyclePhase?
    /// 优先级（可选，未提供则使用类型静态默认值）
    public let priority: LifecycleTaskPriority?
    /// 驻留策略（可选，未提供则使用类型静态默认值）
    public let retentionPolicy: LifecycleTaskRetentionPolicy?
    /// 运行参数
    public let args: [String: Sendable]
    /// 工厂类名（可选），用于复杂构造
    public let factoryClassName: String?
    /// 构造器
    public init(className: String,
                phase: AppLifecyclePhase? = nil,
                priority: LifecycleTaskPriority? = nil,
                residency: LifecycleTaskRetentionPolicy? = nil,
                args: [String: Sendable] = [:],
                factoryClassName: String? = nil) {
        self.className = className
        self.phase = phase
        self.priority = priority
        self.retentionPolicy = residency
        self.args = args
        self.factoryClassName = factoryClassName
    }
}
