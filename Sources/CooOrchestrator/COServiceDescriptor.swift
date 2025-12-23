// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义服务描述符，用于从清单文件或宏生成服务元数据，支持延迟实例化。

import Foundation

/// 服务描述符（对应 Manifest 中的一条配置）
public struct COServiceDescriptor: @unchecked Sendable {
    
    /// 服务类
    public let serviceClass: AnyClass
    
    /// 工厂类（可选）
    public let factoryClass: AnyClass?

    /// 指定优先级（可选）
    public let priority: COPriority?
    /// 指定持有策略（可选）
    public let retentionPolicy: CORetentionPolicy?
    /// 静态参数
    public let args: [String: Sendable]
    
    public init(serviceClass: AnyClass,
                priority: COPriority? = nil,
                retentionPolicy: CORetentionPolicy? = nil,
                args: [String: Sendable] = [:],
                factoryClass: AnyClass? = nil) {
        self.serviceClass = serviceClass
        self.priority = priority
        self.retentionPolicy = retentionPolicy
        self.args = args
        self.factoryClass = factoryClass
    }
}
