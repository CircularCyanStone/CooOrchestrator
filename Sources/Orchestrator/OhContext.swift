// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义服务执行的上下文环境，封装事件参数、共享数据与静态配置。
// 类型功能描述：OhContext 是贯穿整个责任链的核心数据对象，承载了运行时环境与用户数据。

import Foundation

/// 服务运行上下文（引用类型，支持责任链数据共享）
/// - Note: 标记为 @unchecked Sendable 以支持携带非 Sendable 的系统对象参数（如 UIApplication）
public final class OhContext: @unchecked Sendable {
    /// 当前触发的生命周期事件
    public let event: OhEvent
    /// 通过清单传入的静态参数集合
    public let args: [String: Sendable]
    /// 动态事件参数（如 application, launchOptions 等）
    public let parameters: [OhParameterKey: Any]
    
    // MARK: - Shared State (Thread Safe)
    /// 内部共享状态容器（引用类型，确保在不同 Context 实例间共享）
    public final class UserInfo: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [OhContextKey: Any] = [:]
        
        public init() {}
        
        public subscript<T>(_ key: OhContextKey) -> T? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storage[key] as? T
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storage[key] = newValue
            }
        }
        
        // MARK: - Convenience Accessors
        
        /// 获取字符串值
        public func getString(_ key: OhContextKey) -> String? {
            self[key]
        }
        
        /// 获取布尔值（支持类型转换：Int/String -> Bool）
        public func getBool(_ key: OhContextKey) -> Bool? {
            // 利用下标语法的锁保护
            let val: Any? = self[key]
            
            if let b = val as? Bool { return b }
            if let i = val as? Int { return i != 0 }
            if let s = val as? String {
                let lower = s.lowercased()
                return lower == "true" || lower == "yes" || lower == "1"
            }
            return nil
        }
        
        /// 获取整数值（支持类型转换：String/Double -> Int）
        public func getInt(_ key: OhContextKey) -> Int? {
            let val: Any? = self[key]
            
            if let i = val as? Int { return i }
            if let d = val as? Double { return Int(d) }
            if let s = val as? String { return Int(s) }
            return nil
        }
        
        /// 获取浮点数值（支持类型转换：String/Int -> Double）
        public func getDouble(_ key: OhContextKey) -> Double? {
            let val: Any? = self[key]
            
            if let d = val as? Double { return d }
            if let i = val as? Int { return Double(i) }
            if let s = val as? String { return Double(s) }
            return nil
        }
        
        /// 获取字典
        public func getDictionary(_ key: OhContextKey) -> [String: Any]? {
            self[key]
        }
        
        /// 获取数组
        public func getArray(_ key: OhContextKey) -> [Any]? {
            self[key]
        }
    }
    
    /// 动态共享数据（线程安全）
    public let userInfo: UserInfo
    
    /// 上下文构造器
    /// - Note: 仅限框架内部使用，外部无需手动创建 Context
    init(event: OhEvent,
                args: [String: Sendable] = [:],
                parameters: [OhParameterKey: Any] = [:],
                userInfo: UserInfo = .init()) {
        self.event = event
        self.args = args
        self.parameters = parameters
        self.userInfo = userInfo
    }
}

/// 上下文共享数据的键名（类型安全包装）
/// - Note: 建议通过扩展定义静态键名，例如 extension OhContextKey { static let userToken = ... }
public struct OhContextKey: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}


