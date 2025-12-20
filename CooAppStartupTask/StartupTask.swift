// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务模块的核心协议与数据模型，定义任务的统一抽象、执行时机、优先级、生命周期与上下文，并提供任务结果类型与描述符用于注册与调度。
// 类型功能描述：StartupTask 协议约束所有任务实现；StartupTaskPhase/StartupTaskPriority/StartupTaskResidency 建模任务的时机、排序与驻留策略；StartupTaskContext/StartupTaskResult 封装运行环境与执行结果；TaskDescriptor 描述清单/宏生成的任务元数据。

import Foundation

/// 启动任务协议
///   通过静态元数据声明任务的“标识/时机/优先级/驻留策略”。
///   限定继承自NSObject，可以通过反射初始化实力对象
///   既然是启动任务为了保障启动速度，肯定要在主线程同步执行用于控制执行顺序，所以限定到MainActor。
///   如需异步任务任务内部进行。
@MainActor
public protocol StartupTask: NSObject {
    /// 任务唯一标识，用于日志标记与常驻持有 Map 的键
    static var id: String { get }
    /// 执行时机（如 `appLaunchEarly`/`appLaunchLate`）
    static var phase: AppStartupPhase { get }
    /// 优先级，数值越大排序越靠前
    static var priority: StartupTaskPriority { get }
    /// 执行完成后的持有策略（常驻或自动销毁）
    static var residency: StartupTaskRetentionPolicy { get }
    
    /// 上下文构造方法，调度器按需注入运行环境与参数
    init(context: StartupTaskContext)
    
    /// 执行任务主体逻辑（需快速返回）；若涉及异步请在内部自管
    func run() -> StartupTaskResult
}

/// 应用启动阶段，任务执行时机（结构体封装，支持自定义扩展）
public struct AppStartupPhase: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// 预设阶段：App 启动完成开始（对应 didFinishLaunchingWithOptions 开始）
    public static let didFinishLaunchBegin = AppStartupPhase(rawValue: "didFinishLaunchBegin")
    /// 预设阶段：App 启动完成结束（对应 didFinishLaunchingWithOptions 结束）
    public static let didFinishLaunchEnd = AppStartupPhase(rawValue: "didFinishLaunchEnd")
    
    // 用户可通过 extension 自定义其他阶段，例如：
    // extension AppStartupPhase { static let homeDidAppear = AppStartupPhase(rawValue: "homeDidAppear") }
}

/// 任务优先级包装（可比较、可发送）
public struct StartupTaskPriority: RawRepresentable, Comparable, Sendable {
    /// 底层优先级数值（越大越先执行）
    public let rawValue: Int
    /// 以原始数值构造优先级
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static func < (lhs: StartupTaskPriority, rhs: StartupTaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// 任务执行后的持有策略（字符串原始值，便于清单直接映射）
public enum StartupTaskRetentionPolicy: String, Sendable {
    /// 执行结束即释放，不被管理器持有
    case destroy​ 
    /// 执行后被管理器以 `id` 持有，直至进程结束或手动清理
    case hold
}

/// 任务执行结果
public struct StartupTaskResult: Sendable {
    /// 是否成功
    public let success: Bool
    /// 可选的简要信息（错误原因或备注）
    public let message: String?
    /// 结果构造器
    public init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
    /// 便捷成功结果
    public static var ok: StartupTaskResult { .init(success: true) }
    /// 便捷失败结果
    public static func fail(_ message: String?) -> StartupTaskResult { .init(success: false, message: message) }
}

/// 任务运行上下文
public struct StartupTaskContext: Sendable {
    /// 运行环境（如 bundle 等）
    public let environment: AppEnvironment
    /// 通过清单传入的参数集合
    public let args: [String: Sendable]
    /// 上下文构造器
    public init(environment: AppEnvironment, args: [String: Sendable] = [:]) {
        self.environment = environment
        self.args = args
    }
}

/// 基础运行环境
public struct AppEnvironment: Sendable {
    /// 运行的主 Bundle（默认 `.main`）
    public let bundle: Bundle
    /// 环境构造器
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
}

/// 任务描述符（来自 Manifest 或未来宏生成），用于延迟实例化任务
public struct TaskDescriptor: Sendable {
    /// 任务类名（建议包含模块前缀，如 `Module.Class`）
    public let className: String
    /// 执行时机（可选，未提供则使用类型静态默认值）
    public let phase: AppStartupPhase?
    /// 优先级（可选，未提供则使用类型静态默认值）
    public let priority: StartupTaskPriority?
    /// 驻留策略（可选，未提供则使用类型静态默认值）
    public let retentionPolicy: StartupTaskRetentionPolicy?
    /// 运行参数
    public let args: [String: Sendable]
    /// 工厂类名（可选），用于复杂构造
    public let factoryClassName: String?
    /// 构造器
    public init(className: String,
                phase: AppStartupPhase? = nil,
                priority: StartupTaskPriority? = nil,
                residency: StartupTaskRetentionPolicy? = nil,
                args: [String: Sendable] = [:],
                factoryClassName: String? = nil) {
        self.className = className
        self.phase = phase
        self.priority = priority
        self.retentionPolicy = residency
        self.args = args
        self.factoryClassName = factoryClassName
    }
}
