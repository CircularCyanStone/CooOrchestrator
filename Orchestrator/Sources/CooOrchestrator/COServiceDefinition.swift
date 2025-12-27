// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义服务描述符，用于从清单文件或宏生成服务元数据，支持延迟实例化。

import Foundation

/// 服务配置源协议
/// - 职责：提供一组待注册的服务描述符
/// - 扩展：任何模块入口都可以遵循此协议，通过纯代码方式返回该模块的服务列表
public protocol COServiceSource {
    /// 必须提供无参初始化，以便框架通过反射自动加载
    init()
    /// 加载服务描述符
    func load() -> [COServiceDefinition]
}

/// 服务描述符（对应 Manifest 中的一条配置）
public struct COServiceDefinition: @unchecked Sendable {
    
    /// 服务类
    let serviceClass: AnyClass
    
    /// 工厂类（可选）
    let factoryClass: AnyClass?

    /// 指定优先级（可选）
    let priority: COPriority?
    /// 指定持有策略（可选）
    let retentionPolicy: CORetentionPolicy?
    /// 静态参数
    let args: [String: Sendable]
    
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

// MARK: - Convenient Builder
public extension COServiceDefinition {
    /// 便捷构造器（泛型约束，类型安全）
    /// - Parameters:
    ///   - type: 服务类型 (必须遵循 COService)
    ///   - priority: 优先级
    ///   - retention: 驻留策略
    ///   - args: 参数
    /// - Returns: 描述符实例
    static func service<T: COService>(
        _ type: T.Type,
        priority: COPriority? = nil,
        retention: CORetentionPolicy? = nil,
        args: [String: Sendable] = [:]
    ) -> COServiceDefinition {
        return COServiceDefinition(
            serviceClass: type,
            priority: priority,
            retentionPolicy: retention,
            args: args
        )
    }
}
