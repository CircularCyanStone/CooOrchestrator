// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取各模块私有清单（Info.plist 或资源 StartupTasks.plist），解析为任务描述符集合并提供统一的加载入口。
// 类型功能描述：ManifestDiscovery 负责从 bundle 中发现并解析清单；ManifestKeys/ValueParser 提供键名与枚举值解析。

import Foundation

/// Manifest 解析器
/// - 职责：从各模块私有清单读取任务配置并转换为统一的 `TaskDescriptor` 集合。
public enum ManifestDiscovery {
    /// 加载主应用与所有已加载框架的清单并合并
    /// - Returns: 解析得到的任务描述符数组
    public static func loadAllDescriptors() -> [TaskDescriptor] {
        var result: [TaskDescriptor] = []
        // 优化：只扫描 Main Bundle 和内嵌的 Frameworks
        // 排除系统库（如 UIKit, SwiftUI, Foundation 等），大幅减少扫描范围
        let mainBundlePath = Bundle.main.bundlePath
        let allBundles = Bundle.allFrameworks + [Bundle.main]
        
        let targetBundles = allBundles.filter { bundle in
            if bundle == Bundle.main { return true }
            
            // 严谨判断：只处理位于主 App Bundle 内部的 Frameworks (嵌入式 Frameworks)
            // 这包括 .app/Frameworks/ 下的动态库，以及可能的 Plugins
            guard let bundlePath = bundle.bundlePath as String? else { return false }
            return bundlePath.hasPrefix(mainBundlePath)
        }
        
        for bundle in targetBundles {
            result.append(contentsOf: loadDescriptors(in: bundle))
        }
        return result
    }
    
    /// 加载指定 `bundle` 内的清单
    /// - Parameter bundle: 目标模块的 bundle
    /// - Returns: 解析结果数组；若未配置清单则返回空数组
    public static func loadDescriptors(in bundle: Bundle) -> [TaskDescriptor] {
        var descs: [TaskDescriptor] = []
        
        // 尝试加载新 Key (LifecycleTasks) 和旧 Key (StartupTasks)
        let keysToTry = [ManifestKeys.rootNew, ManifestKeys.rootOld]
        
        // 1. Info.plist (极速，推荐)
        if let info = bundle.infoDictionary {
            for key in keysToTry {
                if let arr = info[key] as? [[String: Sendable]] {
                    descs.append(contentsOf: parse(array: arr))
                }
            }
        }
        
        // 2. Resource plist (独立文件，仅作兼容，不推荐)
        // 移除了深度扫描逻辑，仅支持根目录下的标准命名文件
        // 优先查找新文件名
        let filesToTry = ["LifecycleTasks", "StartupTasks"]
        
        for fileName in filesToTry {
            if let url = bundle.url(forResource: fileName, withExtension: "plist"),
               let data = try? Data(contentsOf: url),
               let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
               let arr = obj as? [[String: Sendable]] {
                descs.append(contentsOf: parse(array: arr))
            }
        }
        
        return descs
    }
    
    /// 将清单数组转换为描述符数组
    /// - Parameter array: 解析到的数组对象
    /// - Returns: 合法条目的 `TaskDescriptor` 列表
    private static func parse(array: [[String: Sendable]]) -> [TaskDescriptor] {
        var list: [TaskDescriptor] = []
        for item in array {
            guard let className = item[ManifestKeys.className] as? String else { continue }
            
            let residencyStr = item[ManifestKeys.residency] as? String
            let priorityVal = item[ManifestKeys.priority] as? Int
            let args = item[ManifestKeys.args] as? [String: Sendable] ?? [:]
            let factory = item[ManifestKeys.factory] as? String
            
            let residency = residencyStr.flatMap(LifecycleTaskRetentionPolicy.init(rawValue:))
            let priority = priorityVal.map { LifecycleTaskPriority(rawValue: $0) }
            
            list.append(TaskDescriptor(className: className,
                                       priority: priority,
                                       retentionPolicy: residency,
                                       args: args,
                                       factoryClassName: factory))
        }
        return list
    }
}

/// 清单键名常量
enum ManifestKeys {
    static let rootOld = "StartupTasks"
    static let rootNew = "LifecycleTasks"
    static let className = "class"
    static let priority = "priority"
    static let residency = "residency"
    static let args = "args"
    static let factory = "factory"
}
