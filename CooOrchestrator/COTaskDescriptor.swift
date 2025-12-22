// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义任务描述符，用于从清单文件或宏生成任务元数据，支持延迟实例化。

import Foundation

/// 任务描述符（对应 Manifest 中的一条配置）
public struct COTaskDescriptor: Sendable {
    /// 任务类名
    public let className: String
    /// 指定优先级（可选）
    public let priority: COPriority?
    /// 指定持有策略（可选）
    public let retentionPolicy: CORetentionPolicy?
    /// 静态参数
    public let args: [String: Sendable]
    /// 工厂类名（可选）
    public let factoryClassName: String?
    
    public init(className: String,
                priority: COPriority? = nil,
                retentionPolicy: CORetentionPolicy? = nil,
                args: [String: Sendable] = [:],
                factoryClassName: String? = nil) {
        self.className = className
        self.priority = priority
        self.retentionPolicy = retentionPolicy
        self.args = args
        self.factoryClassName = factoryClassName
    }
}
