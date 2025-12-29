// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：服务编排调度器，支持多线程安全分发，管理服务生命周期与日志。
// 类型功能描述：Orchestrator 作为单例管理器，维护服务注册表、常驻服务持有集合、调度入口 fire(_:) 与注册入口 register(_:)。
/**
 多线程方案选定策略：
 - 为了保证fire方法在传递事件时能保留原方法的执行环境，所以选择了了传统的使用锁来保护多线程的访问安全。
 而使用Concurrency必然面临隔离域切换，一旦切换了就无法感知之前的执行环境了。
 */
import Foundation

/// 服务编排调度器 (Orchestrator)
/// - 职责：统一按“时机 + 优先级”顺序执行服务逻辑；支持责任链分发与流程控制。
/// - 并发模型：非隔离（Non-isolated），内部使用串行队列保护状态。fire 方法在调用者线程执行，支持同步返回值。
public final class Orchestrator: @unchecked Sendable {
    
    // 已经解析的服务条目
    private struct ResolvedServiceEntry: @unchecked Sendable {
        let desc: OhServiceDefinition
        let type: any OhService.Type
        let effEvent: OhEvent
        let effPriority: OhPriority
        let effResidency: OhRetentionPolicy
        // 绑定的处理器（从 Registry 获取）
        // 移除 @Sendable：因为我们保证在调用者线程执行，且 Manager 内部串行管理
        let handler: ((any OhService, OhContext) throws -> OhResult)?
    }
    
    /// 单例实例
    private static let shared = Orchestrator()
    
    /// 内部串行队列，用于保护 descriptors, residentServices, cacheByPhase 等状态
    private let isolationQueue = DispatchQueue(label: "com.coo.orchestrator", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Protected State (Must access via isolationQueue)
    
    /// 已注册的服务类 ID 集合（用于去重）
    private var registeredServiceIDs: Set<ObjectIdentifier> = []
    /// 常驻服务实例表
    private var residentServices: [String: any OhService] = [:]
    /// 是否已完成一次清单引导
    private var hasBootstrapped = false
    /// 分组缓存
    private var cacheByEvent: [OhEvent: [ResolvedServiceEntry]] = [:]
    
    // MARK: - Private / Internal Implementation
    
    private func register(_ newDefinitions: [OhServiceDefinition]) {
        if newDefinitions.isEmpty { return }
        
        var eagerDefs: [OhServiceDefinition] = []
        
        // 改为 sync 确保注册即生效
        // 仅在锁内进行元数据合并，获取需要急切加载的服务列表
        isolationQueue.sync {
            eagerDefs = self.mergeDefinitions(newDefinitions)
        }
        
        // 在锁外进行实例化，避免死锁
        // 因为 instantiateEagerServices 可能会同步等待主线程，
        // 如果放在 isolationQueue.sync 内部，且 register 本身是在主线程调用的，
        // 就会导致 主线程等待 isolationQueue，而 isolationQueue 等待主线程 的死锁。
        if !eagerDefs.isEmpty {
            self.instantiateEagerServices(eagerDefs)
        }
    }
    
    private func resolve(sources: [OhServiceSource]) {
        let start = CFAbsoluteTimeGetCurrent()
        var eagerDefs: [OhServiceDefinition] = []
        
        isolationQueue.sync {
            if !hasBootstrapped {
                // 加载所有源
                var allDefinitions: [OhServiceDefinition] = []
                for source in sources {
                    allDefinitions.append(contentsOf: source.load())
                }
                
                eagerDefs = self.mergeDefinitions(allDefinitions)
                self.hasBootstrapped = true
                
                let end = CFAbsoluteTimeGetCurrent()
                OhLogger.logPerf("Resolve: Bootstrap completed. Total Cost: \(String(format: "%.4fs", end - start))")
            }
        }
        
        if !eagerDefs.isEmpty {
            self.instantiateEagerServices(eagerDefs)
        }
    }
    
    private func getService<T: OhService>(of type: T.Type) -> T? {
        isolationQueue.sync {
            // 目前仅支持查找已存在的常驻服务
            // 为了安全起见，我们应该通过协议访问 id。
            return self.residentServices[type.id] as? T
        }
    }
    
    @discardableResult
    private func fire(
        _ event: OhEvent,
        parameters: [OhParameterKey: Any] = [:]
    ) -> OhReturnValue {
        
        // 1. 引导加载与读取服务列表
        // 优化：将 Bootstrap 检查与任务预加载合并在一个 sync 锁中，减少锁切换开销
        let tasks: [(entry: ResolvedServiceEntry, service: (any OhService)?)] = isolationQueue.sync {
            // 1.1 Lazy Bootstrap Check
            if !hasBootstrapped {
                // 默认仅加载 Manifest
                let discovered = OhManifestScanner.loadAllDefinitions()
                _ = self.mergeDefinitions(discovered)
                self.hasBootstrapped = true
            }
            
            // 1.2 Snapshot & Preload
            let entries = cacheByEvent[event] ?? []
            return entries.map { entry in
                (entry, self.residentServices[entry.type.id])
            }
        }
        
        // 3. 准备责任链环境
        // 使用 SharedState 来在不同的 Task Context 之间共享数据
        let sharedUserInfo = OhContext.UserInfo()
        var finalReturnValue: OhReturnValue = .void
        
        // 4. 遍历执行（在调用者线程）
        for (item, preloadedService) in tasks {
            // 构造 Context
            let context = OhContext(
                event: event,
                args: item.desc.args,
                parameters: parameters,
                userInfo: sharedUserInfo
            )
            
            // 实例化或获取常驻服务
            var service = preloadedService
            
            // 如果预加载为空（懒加载服务或尚未初始化的常驻服务），则进行实例化
            if service == nil {
                // Double-Check 逻辑：
                // 虽然我们刚才在锁内读了一次是 nil，但在我们执行到这里之前，可能其他线程已经创建了。
                // 所以我们再次检查（这次是在锁内检查，确保原子性）
                
                // 1. Fast path: 再次尝试从缓存读取 (Double Check)
                service = isolationQueue.sync {
                    return self.residentServices[item.type.id]
                }
                
                // 2. Slow path: 依然没有，则在锁外创建
                if service == nil {
                    // 强制在主线程实例化
                    if let created = self.instantiateService(from: item.desc, context: context) {
                        // 3. 写入 (Write Back)
                        if case .hold = item.effResidency {
                            isolationQueue.sync {
                                if let existing = self.residentServices[item.type.id] {
                                    service = existing
                                } else {
                                    self.residentServices[item.type.id] = created
                                    service = created
                                }
                            }
                        } else {
                            service = created
                        }
                    }
                }
            }
            
            guard let validService = service else { continue }
            
            let start = CFAbsoluteTimeGetCurrent()
            var isSuccess = true
            var message: String? = nil
            var shouldStop = false
            
            // 执行服务（捕获异常）
            do {
                // 如果有绑定的 Handler，直接调用
                // 如果没有，说明可能是在 Registry 迁移过渡期，或者逻辑错误
                if let handler = item.handler {
                    let result = try handler(validService, context)
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
                        OhLogger.logIntercept(NSStringFromClass(item.desc.serviceClass), event: event)
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
            OhLogger.logTask(
                NSStringFromClass(item.desc.serviceClass),
                event: item.effEvent,
                success: isSuccess,
                message: message,
                cost: end - start
            )
            
            // 处理常驻 (如果是新实例且策略为 hold)
            // 注意：已经在实例化阶段处理了 hold 逻辑，这里只需处理那些
            // 在 fire 过程中动态变为 hold 的情况（极少见，或由 handler 内部触发保持）
            // 现在的逻辑已在上面 Double-Check 中处理了写入，这里可以简化
            
            if shouldStop {
                break
            }
        }
        
        return finalReturnValue
    }
    
    // MARK: - Private Helper
    
    /// 实例化急切加载的服务
    /// - Note: 此方法内部保证在主线程执行实例化，并批量写入常驻服务表
    /// - Warning: **严禁在 isolationQueue.sync 闭包中调用此方法！**
    ///   因为此方法内部会调用 `instantiateService`，后者可能会触发 `DispatchQueue.main.sync`。
    ///   如果在持有 `isolationQueue` 锁的情况下等待主线程，而主线程恰好也在等待 `isolationQueue`（例如正在调用 register），
    ///   将直接导致 **死锁**。
    private func instantiateEagerServices(_ defs: [OhServiceDefinition]) {
        var createdServices: [String: any OhService] = [:]
        
        for def in defs {
            // Context for eager load (no specific event)
            let context = OhContext(event: OhEvent(rawValue: "Orchestrator.EagerLoad"), args: def.args)
            
            // instantiateService 内部已处理主线程调度
            if let service = self.instantiateService(from: def, context: context) {
                if let serviceType = def.serviceClass as? any OhService.Type {
                    createdServices[serviceType.id] = service
                }
            }
        }
        
        if !createdServices.isEmpty {
            // 批量写入，减少锁粒度
            // 使用 sync 确保写入即生效，消除时序不一致
            // 安全性：因为 instantiateEagerServices 必须在锁外调用，所以此处 sync 是安全的
            isolationQueue.sync {
                for (id, service) in createdServices {
                    if self.residentServices[id] == nil {
                        self.residentServices[id] = service
                    }
                }
            }
        }
    }
    
    /// 实例化单个服务
    /// - Warning: **严禁在 isolationQueue.sync 闭包中调用此方法！**
    ///   此方法包含强制主线程执行的逻辑 (`DispatchQueue.main.sync`)。
    ///   如果在持有内部锁时同步等待主线程，极易引发死锁。
    private func instantiateService(
        from desc: OhServiceDefinition,
        context: OhContext
    ) -> (any OhService)? {
        // 强制主线程执行，确保 init 和 serviceDidResolve 在主线程
        if !Thread.isMainThread {
            return DispatchQueue.main.sync {
                self.instantiateService(from: desc, context: context)
            }
        }
        
        let className = NSStringFromClass(desc.serviceClass)
        var service: (any OhService)?
        
        // 优先使用工厂
        if let factoryType = desc.factoryClass as? OhServiceFactory.Type {
            OhLogger.log("Instantiate: Creating \(className) using factory \(NSStringFromClass(factoryType))", level: .debug)
            let factory = factoryType.init()
            service = factory.make(context: context, args: desc.args)
        } else if let serviceType = desc.serviceClass as? any OhService.Type {
            // 直接实例化
            OhLogger.log("Instantiate: Creating \(className) via init()", level: .debug)
            service = serviceType.init()
        } else {
            OhLogger.log("className \(desc.serviceClass) not implement OhService", level: .warning)
            return nil
        }
        
        // 触发初始化后回调
        service?.serviceDidResolve()
        
        return service
    }
    
    private func mergeDefinitions(_ items: [OhServiceDefinition]) -> [OhServiceDefinition] {
        let start = CFAbsoluteTimeGetCurrent()
        // 1. 批量解析类型，避免在循环中多次调用 NSClassFromString
        // 同时过滤掉已经注册过的类（假设类维度去重是业务需求）
        
        var entriesToInsert: [OhEvent: [ResolvedServiceEntry]] = [:]
        var eagerDefinitions: [OhServiceDefinition] = []
        
        // [Debug Log] 输出当前批次扫描到的所有类名
        OhLogger.log("MergeDefinitions: Received \(items.count) descriptors: \(items.map { NSStringFromClass($0.serviceClass) })", level: .debug)
        
        for d in items {
            guard let type = d.serviceClass as? any OhService.Type else { 
                OhLogger.log("MergeDefinitions: \(NSStringFromClass(d.serviceClass)) does not conform to OhService", level: .warning)
                continue
            }
            let typeID = ObjectIdentifier(type)
            
            // 快速去重检查
            if registeredServiceIDs.contains(typeID) { 
                OhLogger.log("MergeDefinitions: Skipped duplicate service \(NSStringFromClass(type))", level: .debug)
                continue
            }
            
            // 标记已注册
            registeredServiceIDs.insert(typeID)
            
            // Check Eager Loading
            // 只有当 isLazy == false 且 retention == .hold 时才进行急切加载
            let effectiveRetention = d.retentionPolicy ?? type.retention
            if !type.isLazy {
                if effectiveRetention == .hold {
                    eagerDefinitions.append(d)
                } else {
                    OhLogger.log("MergeDefinitions: Service \(NSStringFromClass(type)) is marked !isLazy but retention is .destroy. Fallback to lazy.", level: .warning)
                }
            }
            
            // 2. 收集服务里注册的事件和事件的Handlers
            let handlers = self.collectHandlers(for: type)
            if handlers.isEmpty { 
                OhLogger.log("MergeDefinitions: \(NSStringFromClass(type)) has no handlers registered", level: .debug)
                continue
            }
            
            // 3. 内存聚合，而非直接操作 cacheByEvent (减少锁内临界区时间，虽然目前是在 sync 块里)
            for (event, handler) in handlers {
                let entry = ResolvedServiceEntry(
                    desc: d,
                    type: type,
                    effEvent: event,
                    effPriority: d.priority ?? type.priority,
                    effResidency: effectiveRetention,
                    handler: handler
                )
                entriesToInsert[event, default: []].append(entry)
            }
        }
        
        // 4. 批量合并到主缓存并排序
        if !entriesToInsert.isEmpty {
            for (event, newEntries) in entriesToInsert {
                cacheByEvent[event, default: []].append(contentsOf: newEntries)
                // 原地排序，只对受影响的列表排序
                cacheByEvent[event]?.sort { $0.effPriority.rawValue > $1.effPriority.rawValue }
            }
        }
        
        let end = CFAbsoluteTimeGetCurrent()
        OhLogger.logPerf("MergeDefinitions: Processed \(items.count) items, Inserted \(entriesToInsert.count) groups. Cost: \(String(format: "%.4fs", end - start))")
        
        return eagerDefinitions
    }
    
    // 辅助：调用泛型静态方法 register
    private func collectHandlers(for type: any OhService.Type) -> [(OhEvent, (any OhService, OhContext) throws -> OhResult)] {
        return invokeRegister(type)
    }
    
    private func invokeRegister<T: OhService>(_ type: T.Type) -> [(OhEvent, (any OhService, OhContext) throws -> OhResult)] {
        let registry = OhRegistry<T>()
        T.register(in: registry)
        
        return registry.entries.map { entry in
            (entry.event, entry.handler)
        }
    }
}

extension Orchestrator {
    // MARK: - Public API
    
    /// 注册一批服务项
    /// - Parameter newDefinitions: 新增的服务描述符数组
    public static func register(_ newDefinitions: [OhServiceDefinition]) {
        shared.register(newDefinitions)
    }
    
    /// 便捷注册服务（类型安全）
    /// - Parameters:
    ///   - type: 服务类型
    ///   - priority: 覆盖默认优先级（可选）
    ///   - retention: 覆盖默认驻留策略（可选）
    ///   - args: 静态参数（可选）
    public static func register<T: OhService>(
        service type: T.Type,
        priority: OhPriority? = nil,
        retention: OhRetentionPolicy? = nil,
        args: [String: Sendable] = [:]
    ) {
        let desc = OhServiceDefinition(
            serviceClass: type,
            priority: priority,
            retentionPolicy: retention,
            args: args
        )
        shared.register([desc])
    }
    
    /// 启动引导：扫描并加载所有清单中的服务
    /// - Note: 建议在 didFinishLaunching 早期调用，防止被动懒加载导致的时序问题
    /// - Parameter sources: 服务配置源列表（默认包含 Manifest 扫描和 Module 配置加载）
    public static func resolve(sources: [OhServiceSource] = [OhManifestScanner(), OhModuleScanner(), OhSectionScanner()]) {
        shared.resolve(sources: sources)
    }
    
    /// 触发指定时机的服务执行
    /// - Parameters:
    ///   - event: 执行时机
    ///   - parameters: 动态事件参数（如 application, launchOptions 等）
    ///   - environment: 运行环境对象
    /// - Returns: 最终的执行结果（如果被中断，则返回中断时的值；否则返回 .void）
    @discardableResult
    public static func fire(
        _ event: OhEvent,
        parameters: [OhParameterKey: Any] = [:]
    ) -> OhReturnValue {
        return shared.fire(event, parameters: parameters)
    }
    
    /// 触发服务执行并获取泛型返回值
    /// - Note: 这是 fire(_:environment:) 的便捷泛型封装
    @discardableResult
    public static func fire<T>(
        _ event: OhEvent,
        parameters: [OhParameterKey: Any] = [:],
    ) -> T? {
        let ret = shared.fire(event, parameters: parameters)
        return ret.value()
    }
    
    /// 获取常驻服务实例
    /// - Parameter type: 服务类型
    /// - Returns: 如果该服务已被加载且策略为常驻 (.hold)，则返回实例；否则返回 nil
    public static func service<T: OhService>(of type: T.Type) -> T? {
        return shared.getService(of: type)
    }
}
