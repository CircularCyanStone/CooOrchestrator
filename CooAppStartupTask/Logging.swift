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
    
    /// 日志开关（默认开启，以便调试启动流程，生产环境建议关闭）
    public static var isEnabled: Bool = true
    
    /// 记录性能/调试日志
    public static func logPerf(_ message: String) {
        guard isEnabled else { return }
        print("[Lifecycle] [Performance] \(message)")
    }
    
    /// 记录任务执行日志
    /// - Parameters:
    ///   - className: 任务类名
    ///   - event: 执行时机
    ///   - success: 是否成功
    ///   - message: 附加信息
    ///   - cost: 耗时（秒）
    public static func logTask(_ className: String,
                        event: AppLifecycleEvent,
                        success: Bool,
                        message: String? = nil,
                        cost: TimeInterval = 0) {
        guard isEnabled else { return }
        let status = success ? "✅" : "❌"
        let costStr = String(format: "%.4fs", cost)
        let msg = message.map { " - \($0)" } ?? ""
        print("[Lifecycle] [\(event.rawValue)] \(status) \(className) (\(costStr))\(msg)")
    }
    
    /// 记录显式拦截
    public static func logIntercept(_ className: String, event: AppLifecycleEvent) {
        guard isEnabled else { return }
        print("[Lifecycle] [\(event.rawValue)] 🛑 Intercepted by \(className)")
    }
}
