// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：为需要复杂初始化的任务提供工厂协议与默认约定，支持从清单参数构建任务实例。
// 类型功能描述：StartupTaskFactory 定义统一构造入口；默认要求可无参初始化，并通过 make(context:args:) 返回任务。

import Foundation

@MainActor
/// 启动任务工厂协议
/// - 适用场景：任务初始化需要外部依赖或复杂参数拼装时，通过工厂完成构造，
///   并由清单通过 `factory` 字段指定对应的工厂类型。
public protocol StartupTaskFactory: AnyObject {
    /// 要求可无参初始化，便于通过类名反射创建工厂实例
    init()
    /// 根据上下文与参数创建任务实例
    /// - Parameters:
    ///   - context: 任务上下文
    ///   - args: 清单透传的参数字典
    /// - Returns: 构造完成的任务实例
    func make(context: StartupTaskContext, args: [String: Any]) -> StartupTask
}
