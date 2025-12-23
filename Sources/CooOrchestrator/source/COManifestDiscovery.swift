// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取各模块私有清单（Info.plist 或资源 COServices.plist），解析为服务描述符集合并提供统一的加载入口。
// 类型功能描述：COManifestDiscovery 负责从 bundle 中发现并解析清单；ManifestKeys/ValueParser 提供键名与枚举值解析。

import Foundation

/// 清单键名常量
enum ManifestKeys {
    static let root = "COServices"
    static let className = "class"
    static let priority = "priority"
    static let retention = "retention"
    static let args = "args"
    static let factory = "factory"
}

/// Manifest 解析器
/// - 职责：从各模块私有清单读取服务配置并转换为统一的 `COServiceDescriptor` 集合。
public struct COManifestDiscovery: COServiceSource {
    
    public init() {}
    
    public func load() -> [COServiceDescriptor] {
        return Self.loadAllDescriptors()
    }
    
    /// 线程安全的描述符收集器
    private class DescriptorCollector: @unchecked Sendable {
        private var items: [COServiceDescriptor] = []
        private let lock = NSLock()
        
        func append(_ newItems: [COServiceDescriptor]) {
            lock.lock()
            items.append(contentsOf: newItems)
            lock.unlock()
        }
        
        var allItems: [COServiceDescriptor] {
            lock.lock()
            defer { lock.unlock() }
            return items
        }
    }

    /// 加载主应用与所有已加载框架的清单并合并
    /// - Returns: 解析得到的服务描述符数组
    static func loadAllDescriptors() -> [COServiceDescriptor] {
        let start = CFAbsoluteTimeGetCurrent()
        var result: [COServiceDescriptor] = []
        
        // 1. 获取目标 Bundles (Main + Embedded Frameworks)
        let findBundleStart = CFAbsoluteTimeGetCurrent()
        var targetBundles = [Bundle.main]
        
        // 2. 扫描 Frameworks 目录 (动态库)
        if let frameworksURL = Bundle.main.privateFrameworksURL,
           let urls = try? FileManager.default.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for url in urls {
                if url.pathExtension == "framework", let bundle = Bundle(url: url) {
                    targetBundles.append(bundle)
                }
            }
        }
        
        // 3. 扫描 Resource Bundles (静态库通常将资源打包为 .bundle 放入主包)
        if let resourceURL = Bundle.main.resourceURL,
           let urls = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for url in urls {
                // 过滤掉系统可能生成的非资源 bundle (如有必要可加更多过滤条件)
                if url.pathExtension == "bundle", let bundle = Bundle(url: url) {
                    targetBundles.append(bundle)
                }
            }
        }
        
        let findBundleCost = CFAbsoluteTimeGetCurrent() - findBundleStart
        
        // 4. 扫描 Bundles (并发优化)
        let scanStart = CFAbsoluteTimeGetCurrent()
        
        // 使用 Collector 封装锁与状态，规避闭包捕获 var 的检查
        let collector = DescriptorCollector()
        let bundlesToScan = targetBundles
        
        DispatchQueue.concurrentPerform(iterations: bundlesToScan.count) { index in
            let bundle = bundlesToScan[index]
            let descriptors = loadDescriptors(in: bundle)
            if !descriptors.isEmpty {
                collector.append(descriptors)
            }
        }
        result.append(contentsOf: collector.allItems)
        
        let scanCost = CFAbsoluteTimeGetCurrent() - scanStart
        
        let end = CFAbsoluteTimeGetCurrent()
        
        let totalCost = end - start
        var logMsg = "COManifestDiscovery: Scanned \(targetBundles.count) bundles, found \(result.count) services. Cost: \(String(format: "%.4fs", totalCost))\n"
        logMsg += " - Find Bundles   : \(String(format: "%.4fs", findBundleCost))\n"
        logMsg += " - Scan Bundles   : \(String(format: "%.4fs", scanCost))"
        
        COLogger.logPerf(logMsg)
        
        return result
    }
    
    /// 加载指定 `bundle` 内的清单
    /// - Parameter bundle: 目标模块的 bundle
    /// - Returns: 解析结果数组；若未配置清单则返回空数组
    static func loadDescriptors(in bundle: Bundle) -> [COServiceDescriptor] {
        var descs: [COServiceDescriptor] = []
        let start = CFAbsoluteTimeGetCurrent()
        
        // 1. Info.plist (极速，推荐)
        if let info = bundle.infoDictionary {
            if let arr = info[ManifestKeys.root] as? [[String: Sendable]] {
                descs.append(contentsOf: parse(array: arr))
            }
        }
        let afterInfo = CFAbsoluteTimeGetCurrent()
        
        // 2. Resource plist (独立文件，仅作兼容，不推荐)
        var resIOCost: TimeInterval = 0
        var resParseCost: TimeInterval = 0
        
        if let url = bundle.url(forResource: "COServices", withExtension: "plist") {
            let ioStart = CFAbsoluteTimeGetCurrent()
            // 细分IO：Data读取 vs Plist反序列化
            if let arr = NSArray(contentsOf: url) as? [[String: Sendable]] {
                // IO部分结束（含反序列化）
                resIOCost = CFAbsoluteTimeGetCurrent() - ioStart
                
                // Parse部分
                let parseStart = CFAbsoluteTimeGetCurrent()
                let parsed = parse(array: arr)
                resParseCost = CFAbsoluteTimeGetCurrent() - parseStart
                
                descs.append(contentsOf: parsed)
            }
        }
        let afterRes = CFAbsoluteTimeGetCurrent()
        
        // 统计耗时
        let totalCost = afterRes - start
        let infoCost = afterInfo - start
        let resTotalCost = afterRes - afterInfo
        
        // 强制输出，不受阈值限制，便于调试
        var msg = " - Scan \(bundle.bundleIdentifier ?? "unknown"): \(String(format: "%.6fs", totalCost))\n"
        msg += "   |-- Info: \(String(format: "%.6fs", infoCost))\n"
        msg += "   |-- Res : \(String(format: "%.6fs", resTotalCost)) (IO: \(String(format: "%.6fs", resIOCost)), Parse: \(String(format: "%.6fs", resParseCost)))"
        
        COLogger.logPerf(msg)
        
        return descs
    }
    
    /// 将清单数组转换为描述符数组
    /// - Parameter array: 解析到的数组对象
    /// - Returns: 合法条目的 `COServiceDescriptor` 列表
    private static func parse(array: [[String: Sendable]]) -> [COServiceDescriptor] {
        var list: [COServiceDescriptor] = []
        for item in array {
            guard let className = item[ManifestKeys.className] as? String else {
                COLogger.log("Warning: className not exsit in manifest.")
                continue
            }
            
            // 立即转换为 Class，如果转换失败则跳过
            guard let serviceClass = NSClassFromString(className) else {
                COLogger.log("Warning: Failed to resolve class '\(className)' from manifest.")
                continue
            }
            
            let retentionStr = item[ManifestKeys.retention] as? String
            let priorityVal = item[ManifestKeys.priority] as? Int
            let args = item[ManifestKeys.args] as? [String: Sendable] ?? [:]
            let factoryName = item[ManifestKeys.factory] as? String
            
            var factoryClass: AnyClass? = nil
            if let fName = factoryName {
                factoryClass = NSClassFromString(fName)
                if factoryClass == nil {
                     COLogger.log("Warning: Failed to resolve factory class '\(fName)' for service '\(className)'.")
                }
            }
            
            let retention = retentionStr.flatMap(CORetentionPolicy.init(rawValue:))
            let priority = priorityVal.map { COPriority(rawValue: $0) }
            
            list.append(COServiceDescriptor(serviceClass: serviceClass,
                                       priority: priority,
                                       retentionPolicy: retention,
                                       args: args,
                                       factoryClass: factoryClass))
        }
        return list
    }
}
