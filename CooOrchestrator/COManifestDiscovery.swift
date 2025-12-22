// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取各模块私有清单（Info.plist 或资源 LifecycleTasks.plist），解析为服务描述符集合并提供统一的加载入口。
// 类型功能描述：COManifestDiscovery 负责从 bundle 中发现并解析清单；ManifestKeys/ValueParser 提供键名与枚举值解析。

import Foundation

/// Manifest 解析器
/// - 职责：从各模块私有清单读取服务配置并转换为统一的 `COServiceDescriptor` 集合。
public enum COManifestDiscovery {
    /// 加载主应用与所有已加载框架的清单并合并
    /// - Returns: 解析得到的服务描述符数组
    public static func loadAllDescriptors() -> [COServiceDescriptor] {
        let start = CFAbsoluteTimeGetCurrent()
        var result: [COServiceDescriptor] = []
        
        // 优化：只扫描 Main Bundle 和内嵌的 Frameworks
        // 排除系统库（如 UIKit, SwiftUI, Foundation 等），大幅减少扫描范围
        let mainBundlePath = Bundle.main.bundlePath
        let allBundles = Bundle.allFrameworks + [Bundle.main]
        
        let targetBundles = allBundles.filter { bundle in
            if bundle == Bundle.main { return true }
            guard let bundlePath = bundle.bundlePath as String? else { return false }
            return bundlePath.hasPrefix(mainBundlePath)
        }
        
        for bundle in targetBundles {
            result.append(contentsOf: loadDescriptors(in: bundle))
        }
        
        let end = CFAbsoluteTimeGetCurrent()
        COLogger.logPerf("COManifestDiscovery: Scanned \(targetBundles.count) bundles, found \(result.count) services. Cost: \(String(format: "%.4fs", end - start))")
        
        return result
    }
    
    /// 加载指定 `bundle` 内的清单
    /// - Parameter bundle: 目标模块的 bundle
    /// - Returns: 解析结果数组；若未配置清单则返回空数组
    public static func loadDescriptors(in bundle: Bundle) -> [COServiceDescriptor] {
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
            if let data = try? Data(contentsOf: url) {
                let plistStart = CFAbsoluteTimeGetCurrent()
                if let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                   let arr = obj as? [[String: Sendable]] {
                    // IO部分结束（含反序列化）
                    resIOCost = CFAbsoluteTimeGetCurrent() - ioStart
                    
                    // Parse部分
                    let parseStart = CFAbsoluteTimeGetCurrent()
                    let parsed = parse(array: arr)
                    resParseCost = CFAbsoluteTimeGetCurrent() - parseStart
                    
                    descs.append(contentsOf: parsed)
                }
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
        let start = CFAbsoluteTimeGetCurrent()
        var list: [COServiceDescriptor] = []
        for item in array {
            guard let className = item[ManifestKeys.className] as? String else { continue }
            
            let retentionStr = item[ManifestKeys.retention] as? String
            let priorityVal = item[ManifestKeys.priority] as? Int
            let args = item[ManifestKeys.args] as? [String: Sendable] ?? [:]
            let factory = item[ManifestKeys.factory] as? String
            
            let retention = retentionStr.flatMap(CORetentionPolicy.init(rawValue:))
            let priority = priorityVal.map { COPriority(rawValue: $0) }
            
            list.append(COServiceDescriptor(className: className,
                                       priority: priority,
                                       retentionPolicy: retention,
                                       args: args,
                                       factoryClassName: factory))
        }
        
        let cost = CFAbsoluteTimeGetCurrent() - start
        // COLogger.logPerf("   -> Parse \(list.count) items cost: \(String(format: "%.6fs", cost))")
        
        return list
    }
}

/// 清单键名常量
enum ManifestKeys {
    static let root = "COServices"
    static let className = "class"
    static let priority = "priority"
    static let retention = "retention"
    static let args = "args"
    static let factory = "factory"
}
