// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：统一的启动任务日志记录封装，提供任务执行的成功/失败、时机与耗时信息上报。
// 类型功能描述：Logging 提供静态方法进行 OSLog 打点（如不可用则回退到 print），供调度器调用。

import Foundation
import os

/// 启动任务日志工具
/// - 使用 `OSLog` 记录任务执行信息；若系统不支持或失败，自动降级到 `print`（由 `Logger` 处理）。
public enum Logging {
    /// 日志子系统标识，默认取主 bundle 标识
    static let subsystem = Bundle.main.bundleIdentifier ?? "CooAppStartupTask"
    /// 日志分类，固定为启动任务
    static let category = "AppLifecycle"
    /// 系统日志记录器
    static let logger = Logger(subsystem: subsystem, category: category)
    
    /// 记录单个任务的执行信息
    /// - Parameters:
    ///   - className: 任务类名
    ///   - phase: 执行时机
    ///   - success: 是否成功
    ///   - message: 可选消息（错误或备注）
    ///   - cost: 执行耗时（秒）
    public static func logTask(_ className: String,
                        phase: AppLifecyclePhase,
                        success: Bool,
                        message: String?,
                        cost: CFTimeInterval) {
        let status = success ? "OK" : "FAIL"
        logger.log("task=\(className) phase=\(String(describing: phase)) status=\(status) cost=\(cost)s msg=\(message ?? "")")
    }
    
    /// 记录拦截事件（Warning 级别）
    public static func logIntercept(_ className: String, phase: AppLifecyclePhase) {
        logger.warning("🚫 Event '\(phase.rawValue)' was INTERCEPTED by task '\(className)'. Subsequent tasks will NOT be executed.")
    }
}
