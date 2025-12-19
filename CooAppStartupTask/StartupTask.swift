// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务模块的核心协议与数据模型，定义任务的统一抽象、执行时机、优先级、生命周期与上下文，并提供任务结果类型与描述符用于注册与调度。
// 类型功能描述：StartupTask 协议约束所有任务实现；StartupTaskPhase/StartupTaskPriority/StartupTaskResidency 建模任务的时机、排序与驻留策略；StartupTaskContext/StartupTaskResult 封装运行环境与执行结果；TaskDescriptor 描述清单/宏生成的任务元数据。

import Foundation

/// 启动任务协议
/// - 约束：在 `MainActor` 上同步执行，返回快速、可选内部异步；
///   通过静态元数据声明任务的“标识/时机/优先级/驻留策略”。
@MainActor
public protocol StartupTask: AnyObject {
    /// 任务唯一标识，用于日志标记与常驻持有 Map 的键
    static var id: String { get }
    /// 执行时机（如 `appLaunchEarly`/`appLaunchLate`）
    static var phase: StartupTaskPhase { get }
    /// 优先级，数值越大排序越靠前
    static var priority: StartupTaskPriority { get }
    /// 执行完成后的持有策略（常驻或自动销毁）
    static var residency: StartupTaskResidency { get }
    /// 上下文构造方法，调度器按需注入运行环境与参数
    init(context: StartupTaskContext)
    /// 执行任务主体逻辑（需快速返回）；若涉及异步请在内部自管
    func run() -> StartupTaskResult
}

/// 任务执行时机枚举（字符串原始值，便于清单直接映射）
public enum StartupTaskPhase: String, CaseIterable, Sendable {
    case appLaunchEarly = "appLaunchEarly"
    case appLaunchLate = "appLaunchLate"
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
public enum StartupTaskResidency: String, Sendable {
    /// 执行结束即释放，不被管理器持有
    case autoDestroy = "autoDestroy"
    /// 执行后被管理器以 `id` 持有，直至进程结束或手动清理
    case resident = "resident"
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
    public let phase: StartupTaskPhase?
    /// 优先级（可选，未提供则使用类型静态默认值）
    public let priority: StartupTaskPriority?
    /// 驻留策略（可选，未提供则使用类型静态默认值）
    public let residency: StartupTaskResidency?
    /// 运行参数
    public let args: [String: Sendable]
    /// 工厂类名（可选），用于复杂构造
    public let factoryClassName: String?
    /// 构造器
    public init(className: String,
                phase: StartupTaskPhase? = nil,
                priority: StartupTaskPriority? = nil,
                residency: StartupTaskResidency? = nil,
                args: [String: Sendable] = [:],
                factoryClassName: String? = nil) {
        self.className = className
        self.phase = phase
        self.priority = priority
        self.residency = residency
        self.args = args
        self.factoryClassName = factoryClassName
    }
}
