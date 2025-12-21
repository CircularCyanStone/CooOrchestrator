// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：启动任务调度器，支持多线程安全分发，管理任务生命周期与日志。
// 类型功能描述：AppLifecycleManager 作为单例管理器，维护任务注册表、常驻任务持有集合、调度入口 fire(_:) 与注册入口 register(_:)。

import Foundation

/// 启动任务调度器
/// - 职责：统一按“时机 + 优先级”顺序执行任务；支持责任链分发与流程控制。
/// - 并发模型：非隔离（Non-isolated），内部使用串行队列保护状态。fire 方法在调用者线程执行，支持同步返回值。
public final class AppLifecycleManager: @unchecked Sendable {
    
    // 已经解析的任务条目
    private struct ResolvedTaskEntry: @unchecked Sendable {
        let desc: TaskDescriptor
        let type: any AppService.Type
        let effEvent: AppLifecycleEvent
        let effPriority: LifecycleTaskPriority
        let effResidency: LifecycleTaskRetentionPolicy
        // 绑定的处理器（从 Registry 获取）
        // 移除 @Sendable：因为我们保证在调用者线程执行，且 Manager 内部串行管理
        let handler: ((any AppService, LifecycleContext) throws -> LifecycleResult)?
    }
    
    /// 单例实例
    public static let shared = AppLifecycleManager()
    
    /// 内部串行队列，用于保护 descriptors, residentTasks, cacheByPhase 等状态
    private let isolationQueue = DispatchQueue(label: "com.coo.lifecycle.manager", qos: .userInitiated)
    
    /// 服务注册表缓存（Type ID -> Handlers）
    /// 存储每个 Service 类注册的所有事件处理闭包
    private var serviceHandlers: [String: [(AppLifecycleEvent, (any AppService, LifecycleContext) throws -> LifecycleResult)]] = [:]
    
    private init() {}
    
    // MARK: - Protected State (Must access via isolationQueue)
    
    /// 已注册的任务类名集合（用于去重）
    private var registeredClassNames: Set<String> = []
    /// 常驻任务实例表
    private var residentTasks: [String: any AppService] = [:]
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
    
    /// 便捷注册服务（类型安全）
    /// - Parameters:
    ///   - type: 服务类型
    ///   - priority: 覆盖默认优先级（可选）
    ///   - retention: 覆盖默认驻留策略（可选）
    ///   - args: 静态参数（可选）
    public func register<T: AppService>(
        service type: T.Type,
        priority: LifecycleTaskPriority? = nil,
        retention: LifecycleTaskRetentionPolicy? = nil,
        args: [String: Sendable] = [:]
    ) {
        let desc = TaskDescriptor(
            className: NSStringFromClass(type), // 自动获取正确的类名
            priority: priority,
            retentionPolicy: retention,
            args: args
        )
        self.register([desc])
    }
    
    /// 启动引导：扫描并加载所有清单中的任务
    /// - Note: 建议在 didFinishLaunching 早期调用，防止被动懒加载导致的时序问题
    public func resolve() {
        isolationQueue.sync {
            if !hasBootstrapped {
                let discovered = ManifestDiscovery.loadAllDescriptors()
                self.mergeDescriptors(discovered)
                self.hasBootstrapped = true
            }
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
        // 虽然推荐显式调用 resolve()，但为了健壮性，这里保留懒加载兜底
        // 如果用户忘记调用 resolve()，这里会确保第一次 fire 时进行加载
        isolationQueue.sync {
            if !hasBootstrapped {
                let discovered = ManifestDiscovery.loadAllDescriptors()
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
            let taskOrNil = isolationQueue.sync { () -> (any AppService)? in
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
                // 如果有绑定的 Handler，直接调用
                // 如果没有，说明可能是在 Registry 迁移过渡期，或者逻辑错误
                if let handler = item.handler {
                    let result = try handler(task, context)
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
                } else {
                    // Fallback: 如果没有 handler，跳过执行
                    // 在新架构下，必须通过 Registry 注册 handler
                    isSuccess = false
                    message = "No handler registered for event \(event.rawValue)"
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
    ) -> (any AppService)? {
        // 优先使用工厂
        if let factoryName = desc.factoryClassName,
           let factoryType = NSClassFromString(factoryName) as? LifecycleTaskFactory.Type {
            let factory = factoryType.init()
            return factory.make(context: context, args: desc.args)
        }
        
        // 反射实例化
        guard let taskType = NSClassFromString(desc.className) as? any AppService.Type else { return nil }
        let task = taskType.init()
        return task
    }
    
    private func mergeDescriptors(_ items: [TaskDescriptor]) {
        // 1. 批量解析类型，避免在循环中多次调用 NSClassFromString
        // 同时过滤掉已经注册过的类（假设类维度去重是业务需求）
        
        var entriesToInsert: [AppLifecycleEvent: [ResolvedTaskEntry]] = [:]
        
        for d in items {
            // 快速去重检查 (String 比较比 Class 查找快)
            if registeredClassNames.contains(d.className) { continue }
            
            // 昂贵的运行时查找
            guard let type = NSClassFromString(d.className) as? any AppService.Type else { continue }
            
            // 标记已注册
            registeredClassNames.insert(d.className)
            
            // 2. 获取 Handlers (带缓存)
            // 这里的逻辑已经有了缓存，无需大改，但可以提取出来让逻辑更清晰
            let handlers = self.resolveHandlers(for: type)
            if handlers.isEmpty { continue }
            
            // 3. 内存聚合，而非直接操作 cacheByEvent (减少锁内临界区时间，虽然目前是在 sync 块里)
            for (event, handler) in handlers {
                let entry = ResolvedTaskEntry(
                    desc: d,
                    type: type,
                    effEvent: event,
                    effPriority: d.priority ?? type.priority,
                    effResidency: d.retentionPolicy ?? type.retention,
                    handler: handler
                )
                entriesToInsert[event, default: []].append(entry)
            }
        }
        
        // 4. 批量合并到主缓存并排序
        if entriesToInsert.isEmpty { return }
        
        for (event, newEntries) in entriesToInsert {
            cacheByEvent[event, default: []].append(contentsOf: newEntries)
            // 原地排序，只对受影响的列表排序
            cacheByEvent[event]?.sort { $0.effPriority.rawValue > $1.effPriority.rawValue }
        }
    }
    
    // 提取辅助方法，逻辑更清晰
    private func resolveHandlers(for type: any AppService.Type) -> [(AppLifecycleEvent, (any AppService, LifecycleContext) throws -> LifecycleResult)] {
        if let cached = serviceHandlers[type.id] {
            return cached
        }
        let handlers = collectHandlers(for: type)
        serviceHandlers[type.id] = handlers
        return handlers
    }
    
    // 辅助：调用泛型静态方法 register
    private func collectHandlers(for type: any AppService.Type) -> [(AppLifecycleEvent, (any AppService, LifecycleContext) throws -> LifecycleResult)] {
        // 利用 Swift 的运行时特性或辅助协议来调用泛型方法
        // 这里我们需要一个技巧：让 AppService 遵守一个辅助协议，该协议暴露非泛型的 register 入口，或者我们通过反射
        
        // 实际上，最简单的办法是实例化一个 Registry，然后传入。
        // 但 Registry 是泛型的 AppServiceRegistry<Service>。
        // 我们需要构造一个闭包，让 Service 自己去推断类型。
        
        func openExistential<T: AppService>(_ type: T.Type) -> [(AppLifecycleEvent, (any AppService, LifecycleContext) throws -> LifecycleResult)] {
            return invokeRegister(type)
        }
        
        return openExistential(type)
    }
    
    private func invokeRegister<T: AppService>(_ type: T.Type) -> [(AppLifecycleEvent, (any AppService, LifecycleContext) throws -> LifecycleResult)] {
        let registry = AppServiceRegistry<T>()
        T.register(in: registry)
        
        return registry.entries.map { entry in
            (entry.event, entry.handler)
        }
    }
}
