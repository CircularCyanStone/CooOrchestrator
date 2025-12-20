// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务调度器，统一在 MainActor 上按时机与优先级顺序执行任务，管理任务生命周期与日志，并提供对清单/宏生成的任务描述符的注册入口。
// 类型功能描述：StartupTaskManager 作为单例管理器，维护任务注册表、常驻任务持有集合、调度入口 fire(_:) 与注册入口 register(_:)。

import Foundation

@MainActor
/// 启动任务调度器
/// - 职责：统一在 `MainActor` 上按“时机 + 优先级”顺序执行任务；
///   支持自动从清单加载任务描述、常驻任务的生命周期管理与统一日志记录。
public final class StartupTaskManager {
    private struct ResolvedTaskEntry {
        let desc: TaskDescriptor
        let type: StartupTask.Type
        let effPhase: AppStartupPhase
        let effPriority: StartupTaskPriority
        let effResidency: StartupTaskRetentionPolicy
    }
    /// 单例实例，用于在应用生命周期内集中调度所有启动任务
    public static let shared = StartupTaskManager()

    private init() {}

    /// 已注册的任务描述符集合（来自各模块清单合并去重后的结果）
    private var descriptors: [TaskDescriptor] = []
    /// 以任务 `id` 作为键的常驻任务实例表，`resident` 策略的任务会被持有
    private var residentTasks: [String: StartupTask] = [:]
    /// 是否已完成一次清单引导（避免重复解析 bundle 清单）
    private var hasBootstrapped = false
    private var cacheByPhase: [AppStartupPhase: [ResolvedTaskEntry]] = [:]

    /// 注册一批任务描述符
    /// - Parameter newDescriptors: 新增的任务描述符数组（会进行去重合并）
    public func register(_ newDescriptors: [TaskDescriptor]) {
        if newDescriptors.isEmpty { return }
        descriptors.append(contentsOf: newDescriptors)
        descriptors = dedup(descriptors)
        rebuildCache()
    }

    /// 触发指定时机的任务执行
    /// - Parameters:
    ///   - phase: 执行时机（如 `appLaunchEarly`/`appLaunchLate`）
    ///   - environment: 运行环境对象，默认使用 `.main` bundle
    public func fire(
        _ phase: AppStartupPhase,
        environment: AppEnvironment = .init()
    ) {
        if !hasBootstrapped {
            // 首次触发时进行清单发现与加载
            let discovered = ManifestDiscovery.loadAllDescriptors()
            register(discovered)
            hasBootstrapped = true
        }
        let contextBase = StartupTaskContext(environment: environment)
        let phaseDescriptors = cacheByPhase[phase] ?? []
        for item in phaseDescriptors {
            let desc = item.desc
            guard let task = instantiateTask(from: desc, baseContext: contextBase) else { continue }
            let start = CFAbsoluteTimeGetCurrent()
            let result = task.run()
            let end = CFAbsoluteTimeGetCurrent()
            let cost = end - start
            Logging.logTask(
                desc.className,
                phase: item.effPhase,
                success: result.success,
                message: result.message,
                cost: cost
            )
            switch item.effResidency {
            case .hold:
                residentTasks[type(of: task).id] = task
            case .destroy​:
                break
            }
        }
    }

    /// 根据描述符创建任务实例
    /// - Parameters:
    ///   - desc: 任务描述符
    ///   - baseContext: 基础上下文（会合入清单中的 `args`）
    /// - Returns: 创建成功返回任务实例，失败返回 `nil`
    private func instantiateTask(
        from desc: TaskDescriptor,
        baseContext: StartupTaskContext
    ) -> StartupTask? {
        let context = StartupTaskContext(
            environment: baseContext.environment,
            args: desc.args
        )
        if let factoryName = desc.factoryClassName,
            let factoryType = NSClassFromString(factoryName)
                as? StartupTaskFactory.Type
        {
            let factory = factoryType.init()
            return factory.make(context: context, args: desc.args)
        }
        guard
            let taskType = NSClassFromString(desc.className)
                as? StartupTask.Type
        else { return nil }
        let task = taskType.init(context: context)
        return task
    }

    /// 对描述符数组按“类名+时机”键进行去重
    /// - Parameter items: 待去重的描述符数组
    /// - Returns: 去重后的数组，按首次出现顺序稳定保留
    private func dedup(_ items: [TaskDescriptor]) -> [TaskDescriptor] {
        var seen = Set<String>()
        var result: [TaskDescriptor] = []
        for d in items {
            let key = "\(d.className)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(d)
            }
        }
        return result
    }

    
    /// 根据清单配置和静态类型配置，重新组合数据，并根据启动任务阶段提前做好映射关系
    private func rebuildCache() {
        
        /// 将一整个任务数组根据启动阶段重新映射
        var grouped: [AppStartupPhase: [ResolvedTaskEntry]] = [:]
        for d in descriptors {
            guard let type = NSClassFromString(d.className) as? StartupTask.Type else { continue }
            let effPhase = d.phase ?? type.phase
            let entry = ResolvedTaskEntry(
                desc: d,
                type: type,
                effPhase: effPhase,
                effPriority: d.priority ?? type.priority,
                effResidency: d.retentionPolicy ?? type.residency
            )
            grouped[effPhase, default: []].append(entry)
        }
        
        /// 对每个阶段的任务进行排序
        for (p, arr) in grouped {
            grouped[p] = arr.sorted { $0.effPriority.rawValue > $1.effPriority.rawValue }
        }
        cacheByPhase = grouped
    }
}
