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
        isolationQueue.async {
            self.mergeDefinitions(newDefinitions)
        }
    }
    
    private func resolve(sources: [OhServiceSource]) {
        let start = CFAbsoluteTimeGetCurrent()
        isolationQueue.sync {
            if !hasBootstrapped {
                // 加载所有源
                var allDefinitions: [OhServiceDefinition] = []
                for source in sources {
                    allDefinitions.append(contentsOf: source.load())
                }
                
                self.mergeDefinitions(allDefinitions)
                self.hasBootstrapped = true
                
                let end = CFAbsoluteTimeGetCurrent()
                OhLogger.logPerf("Resolve: Bootstrap completed. Total Cost: \(String(format: "%.4fs", end - start))")
            }
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
        
        // 1. 引导加载（如果需要）
        // 虽然推荐显式调用 resolve()，但为了健壮性，这里保留懒加载兜底
        // 如果用户忘记调用 resolve()，这里会确保第一次 fire 时进行加载
        isolationQueue.sync {
            if !hasBootstrapped {
                // 默认仅加载 Manifest
                let discovered = OhManifestDiscovery.loadAllDefinitions()
                self.mergeDefinitions(discovered)
                self.hasBootstrapped = true
            }
        }
        
        // 2. 读取对应事件的服务列表（Snapshot）
        let eventEntries = isolationQueue.sync { cacheByEvent[event] ?? [] }
        
        // 3. 准备责任链环境
        // 使用 SharedState 来在不同的 Task Context 之间共享数据
        let sharedUserInfo = OhContext.UserInfo()
        var finalReturnValue: OhReturnValue = .void
        
        // 4. 遍历执行（在调用者线程）
        for item in eventEntries {
            // 构造 Context
            let context = OhContext(
                event: event,
                args: item.desc.args,
                parameters: parameters,
                userInfo: sharedUserInfo
            )
            
            // 实例化或获取常驻服务
            // 注意：需在 isolationQueue 中安全访问 residentServices
            let serviceOrNil = isolationQueue.sync { () -> (any OhService)? in
                if let resident = self.residentServices[item.type.id] {
                    return resident
                }
                return self.instantiateService(from: item.desc, context: context)
            }
            
            guard let service = serviceOrNil else { continue }
            
            let start = CFAbsoluteTimeGetCurrent()
            var isSuccess = true
            var message: String? = nil
            var shouldStop = false
            
            // 执行服务（捕获异常）
            do {
                // 如果有绑定的 Handler，直接调用
                // 如果没有，说明可能是在 Registry 迁移过渡期，或者逻辑错误
                if let handler = item.handler {
                    let result = try handler(service, context)
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
            if case .hold = item.effResidency {
                isolationQueue.async {
                    if self.residentServices[item.type.id] == nil {
                        self.residentServices[item.type.id] = service
                    }
                }
            }
            
            if shouldStop {
                break
            }
        }
        
        return finalReturnValue
    }
    
    // MARK: - Private Helper
    
    private func instantiateService(
        from desc: OhServiceDefinition,
        context: OhContext
    ) -> (any OhService)? {
        let className = NSStringFromClass(desc.serviceClass)
        
        // 优先使用工厂
        if let factoryType = desc.factoryClass as? OhServiceFactory.Type {
            OhLogger.log("Instantiate: Creating \(className) using factory \(NSStringFromClass(factoryType))", level: .debug)
            let factory = factoryType.init()
            return factory.make(context: context, args: desc.args)
        }
        
        // 直接实例化
        guard let serviceType = desc.serviceClass as? any OhService.Type else {
            OhLogger.log("className \(desc.serviceClass) not implement OhService", level: .warning)
            return nil
        }
        
        OhLogger.log("Instantiate: Creating \(className) via init()", level: .debug)
        let service = serviceType.init()
        return service
    }
    
    private func mergeDefinitions(_ items: [OhServiceDefinition]) {
        let start = CFAbsoluteTimeGetCurrent()
        // 1. 批量解析类型，避免在循环中多次调用 NSClassFromString
        // 同时过滤掉已经注册过的类（假设类维度去重是业务需求）
        
        var entriesToInsert: [OhEvent: [ResolvedServiceEntry]] = [:]
        
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
            
            // 2. 获取 Handlers
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
        
        let end = CFAbsoluteTimeGetCurrent()
        OhLogger.logPerf("MergeDefinitions: Processed \(items.count) items, Inserted \(entriesToInsert.count) groups. Cost: \(String(format: "%.4fs", end - start))")
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
    public static func resolve(sources: [OhServiceSource] = [OhManifestDiscovery(), OhModuleDiscovery(), OhSectionDiscovery()]) {
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
