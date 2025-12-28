// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取主工程配置的模块列表 (OhModules.plist)，并加载对应模块的服务。
// 类型功能描述：OhModuleDiscovery 是基于显式配置的模块加载器，支持二进制库与纯代码注册。

import Foundation

/// 模块配置发现器
/// - 职责：从 `OhModules.plist` 读取模块入口类名，实例化并加载其服务。
/// - 优势：显式、确定、高性能，完全解耦主工程与模块实现。
public struct OhModuleDiscovery: OhServiceSource {
    
    public init() {}
    
    public func load() -> [OhServiceDefinition] {
        var result: [OhServiceDefinition] = []
        
        // 读取主 Bundle 下的 OhModules.plist
        guard let modulesURL = Bundle.main.url(forResource: "OhModules", withExtension: "plist"),
              let moduleNames = NSArray(contentsOf: modulesURL) as? [String] else {
            OhLogger.log("OhModuleDiscovery: OhModules.plist not found or invalid.", level: .warning)
            return []
        }
        
        OhLogger.log("OhModuleDiscovery: Found \(moduleNames.count) modules in config.", level: .info)
        
        for className in moduleNames {
            // 实例化模块入口 (必须遵循 OhServiceSource)
            if let moduleClass = NSClassFromString(className) as? OhServiceSource.Type {
                let module = moduleClass.init()
                let descriptors = module.load()
                result.append(contentsOf: descriptors)
                OhLogger.log("OhModuleDiscovery: Loaded \(descriptors.count) services from \(className)", level: .info)
            } else {
                OhLogger.log("OhModuleDiscovery: Class '\(className)' not found or invalid.", level: .warning)
            }
        }
        
        return result
    }
}
