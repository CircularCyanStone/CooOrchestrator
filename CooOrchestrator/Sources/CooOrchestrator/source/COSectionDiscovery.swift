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
        // 使用泛型 Reader 读取 StaticString 数组
        let entries = SectionReader.read(StaticString.self, section: sectionName)
        
        var classNames = Set<String>()
        for staticStr in entries {
            let str = "\(staticStr)"
            if !str.isEmpty {
                classNames.insert(str)
            }
        }
        return classNames
    }
}

// MARK: - Section Reader Helper

/// 封装 Mach-O 读取逻辑的辅助类型
fileprivate enum SectionReader {
    /// 从指定的 Mach-O Section 读取连续的 T 类型元素数组
    /// - Parameters:
    ///   - type: 读取的元素类型
    ///   - segment: Segment 名称，默认为 "__DATA"
    ///   - section: Section 名称
    /// - Returns: 读取到的元素数组
    static func read<T>(
        _ type: T.Type,
        segment: String = "__DATA",
        section: String
    ) -> [T] {
        let imageCount = _dyld_image_count()
        var infos: [T] = []
        
        // 缓存主 Bundle 路径，避免循环中重复获取
        let mainBundlePath = Bundle.main.bundlePath
        
        // 遍历所有加载的 Mach-O Image
        for i in 0..<imageCount {
            // 1. 过滤：只扫描主 Bundle 及其包含的库
            guard let namePtr = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: namePtr)
            guard imageName.hasPrefix(mainBundlePath) else { continue }
            
            // 2. 获取 Header 并校验
            guard let header = _dyld_get_image_header(i) else { continue }
            guard header.pointee.magic == MH_MAGIC_64 else { continue }
            
            // 转换为 mach_header_64 指针
            let machHeader = UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)
            
            // 3. 获取 Section 数据指针 (getsectiondata 自动处理 ASLR 偏移)
            var size: UInt = 0
            guard let sectionStart = getsectiondata(
                machHeader,
                segment,
                section,
                &size
            ) else { continue }
            
            // 4. 读取数据
            if let buffer = getInfoBuffer(from: UnsafeRawPointer(sectionStart), sectionSize: Int(size), type: T.self) {
                infos.append(contentsOf: buffer)
            }
        }
        
        return infos
    }
    
    /// 创建 UnsafeBufferPointer 以读取连续元素
    private static func getInfoBuffer<InfoType>(
        from sectionStart: UnsafeRawPointer,
        sectionSize: Int,
        type: InfoType.Type
    ) -> UnsafeBufferPointer<InfoType>? {
        guard sectionSize > 0 else { return nil }
        
        let typeSize = MemoryLayout<InfoType>.size
        let typeStride = MemoryLayout<InfoType>.stride
        
        // 计算元素个数 (处理可能的 padding)
        let count: Int
        if sectionSize == typeSize {
            count = 1
        } else {
            count = 1 + (sectionSize - typeSize) / typeStride
        }
        
        let ptr = sectionStart.bindMemory(to: InfoType.self, capacity: count)
        return UnsafeBufferPointer(start: ptr, count: count)
    }
}
