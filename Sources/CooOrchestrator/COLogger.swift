// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：日志系统，支持控制台输出与 OSLog，提供性能与调试信息记录。

import Foundation
import os.log

/// 日志管理器
public enum COLogger: Sendable {
    /// 全局开关（线程安全）
    public static var isEnabled: Bool {
        get { 
            lock.lock()
            defer { lock.unlock() }
            return _isEnabled
        }
        set { 
            lock.lock()
            _isEnabled = newValue
            lock.unlock()
        }
    }
    nonisolated(unsafe) private static var _isEnabled = true
    private static let lock = NSLock()
    
    /// 日志子系统标识，默认取主 bundle 标识
    static let subsystem = Bundle.main.bundleIdentifier ?? "COrchestrator"
    
    /// 记录服务执行日志
    /// - Parameters:
    ///   - className: 服务类名
    ///   - event: 执行时机
    ///   - success: 是否成功
    ///   - message: 附加信息
    ///   - cost: 耗时（秒）
    public static func logTask(_ className: String,
                        event: COEvent,
                        success: Bool,
                        message: String? = nil,
                        cost: TimeInterval = 0) {
        guard isEnabled else { return }
        let status = success ? "✅" : "❌"
        let costStr = String(format: "%.4fs", cost)
        let msg = message.map { " - \($0)" } ?? ""
        print("[Lifecycle] [\(event.rawValue)] \(status) \(className) (\(costStr))\(msg)")
    }
    
    /// 记录拦截日志
    static func logIntercept(_ className: String, event: COEvent) {
        guard isEnabled else { return }
        print("[Lifecycle] [\(event.rawValue)] 🛑 Intercepted by \(className)")
    }
    
    /// 记录性能日志
    static func logPerf(_ message: String) {
        guard isEnabled else { return }
        print("[Lifecycle] [Performance] \(message)")
    }
    
    /// 记录普通日志
    public static func log(_ message: String) {
        guard isEnabled else { return }
        print("[Lifecycle] [Info] \(message)")
    }
}
