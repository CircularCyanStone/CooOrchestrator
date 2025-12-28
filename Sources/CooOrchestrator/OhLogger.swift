// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：日志系统，支持控制台输出与 OSLog，提供性能与调试信息记录。

import Foundation
import os.log

/// 日志管理器
public enum OhLogger: Sendable {
    
    /// 日志级别
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
        
        var icon: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .fault: return "⛔️"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default // OSLog 没有 warning 级别，使用 default
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
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
    
    /// 系统日志记录器 (兼容 iOS 10+)
    private static let logObject = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "Coo.Orchestrator", category: "Lifecycle")
    
    // MARK: - Core Logging
    
    /// 记录日志
    /// - Parameters:
    ///   - message: 日志内容
    ///   - level: 日志级别
    ///   - file: 调用文件
    ///   - function: 调用方法
    ///   - line: 调用行号
    static func log(_ message: String, 
                           level: Level = .info,
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line) {
        guard isEnabled else { return }
        
        let filename = (file as NSString).lastPathComponent
        let meta = "[\(filename):\(line)]"
        let content = "\(level.icon) \(meta) \(message)"
        
        // 使用 %{public}@ 确保字符串内容在生产环境也能显示
        os_log("%{public}@", log: logObject, type: level.osLogType, content)
    }
    
    // MARK: - Convenience Methods
    
    /// 记录服务执行日志
    static func logTask(_ className: String,
                        event: OhEvent,
                        success: Bool,
                        message: String? = nil,
                        cost: TimeInterval = 0) {
        guard isEnabled else { return }
        
        let statusIcon = success ? "✅" : "❌"
        let costStr = String(format: "%.4fs", cost)
        let extraMsg = message.map { " - \($0)" } ?? ""
        let logContent = "[Task] [\(event.rawValue)] \(statusIcon) \(className) (\(costStr))\(extraMsg)"
        
        os_log("%{public}@", log: logObject, type: .info, logContent)
    }
    
    /// 记录拦截日志
    static func logIntercept(_ className: String, event: OhEvent) {
        guard isEnabled else { return }
        let content = "🛑 [Intercept] [\(event.rawValue)] Intercepted by \(className)"
        os_log("%{public}@", log: logObject, type: .info, content)
    }
    
    /// 记录性能日志
    static func logPerf(_ message: String) {
        guard isEnabled else { return }
        let content = "⚡️ [Performance] \(message)"
        os_log("%{public}@", log: logObject, type: .info, content)
    }
}
