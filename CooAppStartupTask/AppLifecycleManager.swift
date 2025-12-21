// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务调度器，支持多线程安全分发，管理任务生命周期与日志。
// 类型功能描述：AppLifecycleManager 作为单例管理器，维护任务注册表、常驻任务持有集合、调度入口 fire(_:) 与注册入口 register(_:)。

import Foundation

/// 启动任务调度器
/// - 职责：统一按“时机 + 优先级”顺序执行任务；支持责任链分发与流程控制。
/// - 并发模型：非隔离（Non-isolated），内部使用串行队列保护状态。fire 方法在调用者线程执行，支持同步返回值。
public final class AppLifecycleManager: @unchecked Sendable {
    
    // 已经解析的任务条目
    private struct ResolvedTaskEntry: Sendable {
        let desc: TaskDescriptor
        let type: AppLifecycleTask.Type
        let effPhase: AppLifecyclePhase
        let effPriority: LifecycleTaskPriority
        let effResidency: LifecycleTaskRetentionPolicy
    }
    
    /// 单例实例
    public static let shared = AppLifecycleManager()
    
    /// 内部串行队列，用于保护 descriptors, residentTasks, cacheByPhase 等状态
    private let isolationQueue = DispatchQueue(label: "com.coo.lifecycle.manager", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Protected State (Must access via isolationQueue)
    
    /// 已注册的任务类名集合（用于去重）
    private var registeredClassNames: Set<String> = []
    /// 常驻任务实例表
    private var residentTasks: [String: AppLifecycleTask] = [:]
    /// 是否已完成一次清单引导
    private var hasBootstrapped = false
    /// 分组缓存
    private var cacheByPhase: [AppLifecyclePhase: [ResolvedTaskEntry]] = [:]
    
    // MARK: - Public API
    
    /// 注册一批任务描述符
    /// - Parameter newDescriptors: 新增的任务描述符数组
    public func register(_ newDescriptors: [TaskDescriptor]) {
        if newDescriptors.isEmpty { return }
        isolationQueue.async {
            self.mergeDescriptors(newDescriptors)
        }
    }
    
    /// 触发指定时机的任务执行
    /// - Parameters:
    ///   - phase: 执行时机
    ///   - environment: 运行环境对象
    /// - Returns: 最终的执行结果（如果被中断，则返回中断时的值；否则返回 .void）
    @discardableResult
    public func fire(
        _ phase: AppLifecyclePhase,
        environment: AppEnvironment = .init()
    ) -> LifecycleReturnValue {
        
        // 1. 引导加载（如果需要）
        isolationQueue.sync {
            if !hasBootstrapped {
                // 1.1. 清单扫描，并解析成清单描述实体
                let discovered = ManifestDiscovery.loadAllDescriptors()
                // 1.2. 合并任务描述
                self.mergeDescriptors(discovered)
                self.hasBootstrapped = true
            }
        }
        
        // 2. 读取对应阶段的任务列表（Snapshot）
        let phaseDescriptors = isolationQueue.sync { cacheByPhase[phase] ?? [] }
        
        // 3. 准备责任链环境
        let sharedUserInfo = LifecycleContextUserInfo()
        var finalReturnValue: LifecycleReturnValue = .void
        
        // 4. 遍历执行（在调用者线程）
        for item in phaseDescriptors {
            // 构造 Context
            let context = LifecycleContext(
                phase: phase,
                environment: environment,
                args: item.desc.args,
                userInfo: sharedUserInfo
            )
            
            // 实例化任务
            guard let task = instantiateTask(from: item.desc, context: context) else { continue }
            
            let start = CFAbsoluteTimeGetCurrent()
            var isSuccess = true
            var message: String? = nil
            var shouldStop = false
            
            // 执行任务（捕获异常）
            do {
                let result = try task.run(context: context)
                switch result {
                case .continue(let s, let m):
                    isSuccess = s
                    message = m
                case .stop(let r, let s, let m):
                    isSuccess = s
                    message = m
                    finalReturnValue = r
                    shouldStop = true
                    // 记录显式拦截
                    Logging.logIntercept(item.desc.className, phase: phase)
                }
            } catch {
                isSuccess = false
                message = "Exception: \(error)"
            }
            
            let end = CFAbsoluteTimeGetCurrent()
            
            // 记录日志
            Logging.logTask(
                item.desc.className,
                phase: item.effPhase,
                success: isSuccess,
                message: message,
                cost: end - start
            )
            
            // 处理常驻
            if case .hold = item.effResidency {
                isolationQueue.async {
                    self.residentTasks[type(of: task).id] = task
                }
            }
            
            if shouldStop {
                break
            }
        }
        
        return finalReturnValue
    }
    
    // MARK: - Private Helper
    
    private func instantiateTask(
        from desc: TaskDescriptor,
        context: LifecycleContext
    ) -> AppLifecycleTask? {
        // 优先使用工厂
        if let factoryName = desc.factoryClassName,
           let factoryType = NSClassFromString(factoryName) as? LifecycleTaskFactory.Type {
            let factory = factoryType.init()
            return factory.make(context: context, args: desc.args)
        }
        
        // 反射实例化
        guard let taskType = NSClassFromString(desc.className) as? AppLifecycleTask.Type else { return nil }
        let task = taskType.init()
        return task
    }
    
    private func mergeDescriptors(_ items: [TaskDescriptor]) {
        var changedPhases: Set<AppLifecyclePhase> = []
        
        for d in items {
            // Deduplication check
            if registeredClassNames.contains(d.className) {
                continue
            }
            
            // Resolve Type
            guard let type = NSClassFromString(d.className) as? AppLifecycleTask.Type else {
                continue
            }
            
            // Mark as registered
            registeredClassNames.insert(d.className)
            
            // Create Entry
            let effPhase = d.phase ?? type.phase
            let entry = ResolvedTaskEntry(
                desc: d,
                type: type,
                effPhase: effPhase,
                effPriority: d.priority ?? type.priority,
                effResidency: d.retentionPolicy ?? type.residency
            )
            
            // Add to Cache
            cacheByPhase[effPhase, default: []].append(entry)
            changedPhases.insert(effPhase)
        }
        
        // Sort modified phases
        for p in changedPhases {
            cacheByPhase[p]?.sort { $0.effPriority.rawValue > $1.effPriority.rawValue }
        }
    }
}
