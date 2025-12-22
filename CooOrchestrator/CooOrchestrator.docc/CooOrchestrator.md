# ``COrchestrator``

一个用于模块化管理应用生命周期与服务分发的编排框架，提供统一的服务协议、时机与优先级、生命周期与自动注册（Manifest），支持多线程安全调度。

## Overview

### 快速开始
- 在业务模块的 `Info.plist` 或资源包添加 `LifecycleTasks.plist`，声明任务：
  - `class`：类全名
  - `priority`：整数，越大越先执行
  - `residency`：`hold`/`destroy`
  - `args`：可选参数字典
- 让任务类型实现 `COService` 协议：
  - 声明静态元数据（`id/priority/retention`）
  - 实现 `register(in:)` 绑定事件
- 在宿主 App 集成：
  - `COrchestrator.shared.fire(.didFinishLaunching)`

### 调度与注册
- 编排器在首次触发时自动加载所有模块的清单并注册任务。
- 按时机聚合、按优先级降序稳定排序、逐个同步执行。
- 基于 `retention` 决定任务的持有与释放。

## Topics

### 核心协议与模型
- ``COService``
- ``COEvent``
- ``COPriority``
- ``CORetentionPolicy``
- ``COContext``
- ``COResult``
- ``COTaskDescriptor``

### 调度器与注册
- ``COrchestrator``
- 清单解析：``COManifestDiscovery``

### 示例
- ``PushNotificationInitTask``
- ``ScreenshotTipTask``
- ``UpgradePromptTask``
