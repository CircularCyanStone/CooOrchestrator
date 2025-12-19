// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取各模块私有清单（Info.plist 或资源 StartupTasks.plist），解析为任务描述符集合并提供统一的加载入口。
// 类型功能描述：ManifestDiscovery 负责从 bundle 中发现并解析清单；ManifestKeys/ValueParser 提供键名与枚举值解析。

import Foundation

/// Manifest 解析器
/// - 职责：从各模块私有清单（模块 `Info.plist` 的 `StartupTasks` 键，或资源包 `StartupTasks.plist`）
///   读取任务配置并转换为统一的 `TaskDescriptor` 集合。
public enum ManifestDiscovery {
    /// 加载主应用与所有已加载框架的清单并合并
    /// - Returns: 解析得到的任务描述符数组
    public static func loadAllDescriptors() -> [TaskDescriptor] {
        var result: [TaskDescriptor] = []
        let bundles = Set(Bundle.allFrameworks + [Bundle.main])
        for bundle in bundles {
            result.append(contentsOf: loadDescriptors(in: bundle))
        }
        return result
    }

    /// 加载指定 `bundle` 内的清单
    /// - Parameter bundle: 目标模块的 bundle
    /// - Returns: 解析结果数组；若未配置清单则返回空数组
    public static func loadDescriptors(in bundle: Bundle) -> [TaskDescriptor] {
        var descs: [TaskDescriptor] = []
        if let info = bundle.infoDictionary,
           let arr = info[ManifestKeys.root] as? [[String: Sendable]] {
            descs.append(contentsOf: parse(array: arr))
        }
        if let url = bundle.url(forResource: ManifestKeys.root, withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let arr = obj as? [[String: Sendable]] {
            descs.append(contentsOf: parse(array: arr))
        }
        if descs.isEmpty {
            let paths = bundle.paths(forResourcesOfType: "plist", inDirectory: nil).filter { $0.hasSuffix("/\(ManifestKeys.root).plist") }
            if let path = paths.first,
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
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
            let phaseStr = item[ManifestKeys.phase] as? String ?? "appLaunchEarly"
            let residencyStr = item[ManifestKeys.residency] as? String ?? "autoDestroy"
            let priorityVal = item[ManifestKeys.priority] as? Int ?? 0
            let args = item[ManifestKeys.args] as? [String: Sendable] ?? [:]
            let factory = item[ManifestKeys.factory] as? String
            guard let phase = StartupTaskPhase(rawValue: phaseStr),
                  let residency = StartupTaskResidency(rawValue: residencyStr) else { continue }
            list.append(TaskDescriptor(className: className,
                                       phase: phase,
                                       priority: StartupTaskPriority(rawValue: priorityVal),
                                       residency: residency,
                                       args: args,
                                       factoryClassName: factory))
        }
        return list
    }
}

/// 清单键名常量
enum ManifestKeys {
    static let root = "StartupTasks"
    static let className = "class"
    static let phase = "phase"
    static let priority = "priority"
    static let residency = "residency"
    static let args = "args"
    static let factory = "factory"
}
