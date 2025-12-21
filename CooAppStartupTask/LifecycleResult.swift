// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义任务执行结果与流程控制指令，以及系统代理方法的返回值封装。

import Foundation

/// 任务执行结果与流程控制
public enum LifecycleResult: Sendable {
    /// 继续传播：当前任务执行完毕，继续执行后续优先级的任务
    /// - success: 任务本身执行是否成功
    /// - message: 可选的日志信息
    case `continue`(success: Bool = true, message: String? = nil)
    
    /// 中断传播：不再执行后续任务（独占处理）
    /// - result: 最终返回给系统的值（默认为 .void）
    /// - success: 任务本身执行是否成功
    /// - message: 可选的日志信息
    case stop(result: LifecycleReturnValue = .void, success: Bool = true, message: String? = nil)
    
    /// 便捷成功结果（等同于 continue）
    public static var ok: LifecycleResult { .continue() }
    /// 便捷失败结果（等同于 continue，但在日志中记录错误）
    public static func fail(_ message: String?) -> LifecycleResult { .continue(success: false, message: message) }
}

/// 系统代理方法的返回值封装
public enum LifecycleReturnValue: Sendable {
    case void          // 无返回值
    case bool(Bool)    // 布尔返回值
}
