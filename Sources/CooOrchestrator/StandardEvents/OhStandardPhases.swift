// Copyright © 2025 Coo. All rights reserved.
// 文件功能描述：定义标准执行阶段事件。
// 类型功能描述：这些事件并非系统原生代理回调，而是对关键生命周期或任务流的细粒度拆分与扩展。

import Foundation

public extension OhEvent {
    
    // MARK: - Launch Phases
    
    /// 通用启动开始阶段
    /// - 含义：标识 App 启动流程的开始点。
    /// - 触发时机：通常在 didFinishLaunching 最开始，或者业务链路的最前端。
    static let appStart = OhEvent(rawValue: "appStart")
    
    /// 通用启动就绪阶段
    /// - 含义：标识 App 启动流程的结束点（Ready）。
    /// - 触发时机：通常在核心启动链路完成后，或者 UI 呈现之后。
    static let appReady = OhEvent(rawValue: "appReady")
    
}
