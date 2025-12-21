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
        let type: AppService.Type
        let effEvent: AppLifecycleEvent
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
    private var residentTasks: [String: AppService] = [:]
    /// 是否已完成一次清单引导
    private var hasBootstrapped = false
    /// 分组缓存
    private var cacheByEvent: [AppLifecycleEvent: [ResolvedTaskEntry]] = [:]
    
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
    ///   - event: 执行时机
    ///   - parameters: 动态事件参数（如 application, launchOptions 等）
    ///   - environment: 运行环境对象
    /// - Returns: 最终的执行结果（如果被中断，则返回中断时的值；否则返回 .void）
    @discardableResult
    public func fire(
        _ event: AppLifecycleEvent,
        parameters: [LifecycleParameterKey: Any] = [:],
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
        let eventEntries = isolationQueue.sync { cacheByEvent[event] ?? [] }
        
        // 3. 准备责任链环境
        let sharedUserInfo = LifecycleContextUserInfo()
        var finalReturnValue: LifecycleReturnValue = .void
        
        // 4. 遍历执行（在调用者线程）
        for item in eventEntries {
            // 构造 Context
            let context = LifecycleContext(
                event: event,
                environment: environment,
                args: item.desc.args,
                parameters: parameters,
                userInfo: sharedUserInfo
            )
            
            // 实例化或获取常驻任务
            // 注意：需在 isolationQueue 中安全访问 residentTasks
            let taskOrNil = isolationQueue.sync { () -> AppService? in
                if let resident = self.residentTasks[item.type.id] {
                    return resident
                }
                return self.instantiateTask(from: item.desc, context: context)
            }
            
            guard let task = taskOrNil else { continue }
            
            let start = CFAbsoluteTimeGetCurrent()
            var isSuccess = true
            var message: String? = nil
            var shouldStop = false
            
            // 执行任务（捕获异常）
            do {
                let result = try task.serve(context: context)
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
                    Logging.logIntercept(item.desc.className, event: event)
                }
            } catch {
                isSuccess = false
                message = "Exception: \(error)"
            }
            
            let end = CFAbsoluteTimeGetCurrent()
            
            // 记录日志
            Logging.logTask(
                item.desc.className,
                event: item.effEvent,
                success: isSuccess,
                message: message,
                cost: end - start
            )
            
            // 处理常驻 (如果是新实例且策略为 hold)
            if case .hold = item.effResidency {
                isolationQueue.async {
                    if self.residentTasks[item.type.id] == nil {
                        self.residentTasks[item.type.id] = task
                    }
                }
            }
            
            if shouldStop {
                break
            }
        }
        
        return finalReturnValue
    }
    
    /// 触发任务执行并获取泛型返回值
    /// - Note: 这是 fire(_:environment:) 的便捷泛型封装
    @discardableResult
    public func fire<T>(
        _ event: AppLifecycleEvent,
        parameters: [LifecycleParameterKey: Any] = [:],
        environment: AppEnvironment = .init()
    ) -> T? {
        let ret = fire(event, parameters: parameters, environment: environment)
        return ret.value()
    }
    
    // MARK: - Private Helper
    
    private func instantiateTask(
        from desc: TaskDescriptor,
        context: LifecycleContext
    ) -> AppService? {
        // 优先使用工厂
        if let factoryName = desc.factoryClassName,
           let factoryType = NSClassFromString(factoryName) as? LifecycleTaskFactory.Type {
            let factory = factoryType.init()
            return factory.make(context: context, args: desc.args)
        }
        
        // 反射实例化
        guard let taskType = NSClassFromString(desc.className) as? AppService.Type else { return nil }
        let task = taskType.init()
        return task
    }
    
    private func mergeDescriptors(_ items: [TaskDescriptor]) {
        var changedEvents: Set<AppLifecycleEvent> = []
        
        for d in items {
            // Deduplication check
            if registeredClassNames.contains(d.className) {
                continue
            }
            
            // Resolve Type
            guard let type = NSClassFromString(d.className) as? AppService.Type else {
                continue
            }
            
            // Mark as registered
            registeredClassNames.insert(d.className)
            
            // Determine interested events
            // 从类静态属性中获取订阅事件（替代 Manifest 配置）
            let events = type.events
            
            for event in events {
                let entry = ResolvedTaskEntry(
                    desc: d,
                    type: type,
                    effEvent: event,
                    effPriority: d.priority ?? type.priority,
                    effResidency: d.retentionPolicy ?? type.retention
                )
                
                // Add to Cache
                cacheByEvent[event, default: []].append(entry)
                changedEvents.insert(event)
            }
        }
        
        // Sort modified phases
        for p in changedEvents {
            cacheByEvent[p]?.sort { $0.effPriority.rawValue > $1.effPriority.rawValue }
        }
    }
}
