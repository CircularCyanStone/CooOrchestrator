// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：读取主工程配置的模块列表 (COModules.plist)，并加载对应模块的服务。
// 类型功能描述：COModuleDiscovery 是基于显式配置的模块加载器，支持二进制库与纯代码注册。

import Foundation

/// 模块配置发现器
/// - 职责：从 `COModules.plist` 读取模块入口类名，实例化并加载其服务。
/// - 优势：显式、确定、高性能，完全解耦主工程与模块实现。
public struct COModuleDiscovery: COServiceSource {
    
    public init() {}
    
    public func load() -> [COServiceDefinition] {
        var result: [COServiceDefinition] = []
        
        // 读取主 Bundle 下的 COModules.plist
        guard let modulesURL = Bundle.main.url(forResource: "COModules", withExtension: "plist"),
              let moduleNames = NSArray(contentsOf: modulesURL) as? [String] else {
            COLogger.log("COModuleDiscovery: COModules.plist not found or invalid.")
            return []
        }
        
        COLogger.log("COModuleDiscovery: Found \(moduleNames.count) modules in config.")
        
        for className in moduleNames {
            // 实例化模块入口 (必须遵循 COServiceSource)
            if let moduleClass = NSClassFromString(className) as? COServiceSource.Type {
                let module = moduleClass.init()
                let descriptors = module.load()
                result.append(contentsOf: descriptors)
                COLogger.log("COModuleDiscovery: Loaded \(descriptors.count) services from \(className)")
            } else {
                COLogger.log("COModuleDiscovery: Warning - Class '\(className)' not found or invalid.")
            }
        }
        
        return result
    }
}
