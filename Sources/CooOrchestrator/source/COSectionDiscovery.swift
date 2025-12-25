// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：基于 Mach-O Section 注入的自动发现方案。
// 类型功能描述：COSectionDiscovery 扫描二进制段中的注册信息，支持模块级与服务级双重注册模式。

import Foundation
import MachO

/// Mach-O Section 发现器
/// - 职责：扫描 `__DATA` 段下的自定义 Section，自动发现并加载服务。
/// - 特点：无中心化配置，编译期注入，运行期直接读取内存。
public struct COSectionDiscovery: COServiceSource {
    
    // MARK: - Constants
    
    /// 模块注册段名 (存储遵循 COServiceSource 的类名)
    private static let sectionModule = "__coo_mod"
    
    /// 服务注册段名 (存储遵循 COService 的类名)
    private static let sectionService = "__coo_svc"
    
    /// Mach-O 段名称 (通常为 __DATA)
    private static let segmentName = "__DATA"
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - COServiceSource
    
    public func load() -> [COServiceDefinition] {
        var results: [COServiceDefinition] = []
        let start = CFAbsoluteTimeGetCurrent()
        
        // 1. 扫描模块注册段
        let moduleClasses = scanMachO(sectionName: Self.sectionModule)
        for className in moduleClasses {
            if let type = NSClassFromString(className) as? COServiceSource.Type {
                let instance = type.init()
                let moduleServices = instance.load()
                results.append(contentsOf: moduleServices)
                COLogger.log("COSectionDiscovery: Loaded module '\(className)' with \(moduleServices.count) services.")
            } else {
                COLogger.log("COSectionDiscovery: Warning - Class '\(className)' in \(Self.sectionModule) is not a valid COServiceSource.")
            }
        }
        
        // 2. 扫描服务注册段
        let serviceClasses = scanMachO(sectionName: Self.sectionService)
        for className in serviceClasses {
            if let type = NSClassFromString(className) as? (any COService.Type) {
                // 直接构造定义，使用协议默认属性
                // 注意：如果服务需要自定义参数(args)，目前这种轻量级注册暂不支持，需走模块级注册或 plist
                let def = COServiceDefinition.service(type)
                results.append(def)
            } else {
                COLogger.log("COSectionDiscovery: Warning - Class '\(className)' in \(Self.sectionService) is not a valid COService.")
            }
        }
        
        let cost = CFAbsoluteTimeGetCurrent() - start
        if !results.isEmpty {
            COLogger.logPerf("COSectionDiscovery: Scanned \(moduleClasses.count) modules, \(serviceClasses.count) services. Cost: \(String(format: "%.4fs", cost))")
        }
        
        return results
    }
    
    // MARK: - Mach-O Scanning
    
    /// 扫描所有 Image 的指定 Section
    /// - Returns: 唯一的类名集合
    private func scanMachO(sectionName: String) -> Set<String> {
        var classNames = Set<String>()
        
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let header = _dyld_get_image_header(i) else { continue }
            
            // 仅处理 64 位 Mach-O
            if header.pointee.magic == MH_MAGIC_64 {
                let header64 = header.withMemoryRebound(to: mach_header_64.self, capacity: 1) { $0 }
                
                // 查找 Section
                if let section = getsectbynamefromheader_64(header64, Self.segmentName, sectionName) {
                    // 计算真实内存地址
                    // slide 是 intptr_t (Int), addr 是 UInt64
                    let slide = _dyld_get_image_vmaddr_slide(i)
                    let linkAddr = section.pointee.addr
                    // 安全转换并计算: slide + linkAddr
                    let startAddr = UInt(bitPattern: slide) &+ UInt(linkAddr)
                    let size = section.pointee.size
                    
                    // 遍历 Section 内容
                    // 内容是 char* 数组 (存储的是指向类名字符串的指针)
                    let entryCount = Int(size) / MemoryLayout<UnsafePointer<CChar>>.size
                    
                    if let rawPtr = UnsafeRawPointer(bitPattern: startAddr) {
                        let ptrList = rawPtr.bindMemory(to: UnsafePointer<CChar>.self, capacity: entryCount)
                        
                        for j in 0..<entryCount {
                            let cStringPtr = ptrList[j]
                            // 读取 C 字符串
                            let str = String(cString: cStringPtr)
                            // 简单的过滤，避免空串
                            if !str.isEmpty {
                                classNames.insert(str)
                            }
                        }
                    }
                }
            }
        }
        
        return classNames
    }
}
