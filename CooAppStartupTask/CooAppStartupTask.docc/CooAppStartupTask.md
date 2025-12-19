# ``CooAppStartupTask``

一个用于模块化管理应用启动任务的框架，提供统一的任务协议、时机与优先级、生命周期与自动注册（Manifest），并在 MainActor 上同步执行。

## Overview

### 快速开始
- 在业务模块的 `Info.plist` 或资源包添加 `StartupTasks.plist`，声明任务：
  - `class`：类全名
  - `phase`：`appLaunchEarly`/`appLaunchLate`
  - `priority`：整数，越大越先执行
  - `residency`：`resident`/`autoDestroy`
  - `args`：可选参数字典
- 让任务类型实现 `StartupTask` 协议：
  - 声明静态元数据（`id/phase/priority/residency`）
  - 实现 `init(context:)` 与 `run()`
- 在宿主 App 集成：
  - `StartupTaskManager.shared.fire(.appLaunchEarly)`
  - `StartupTaskManager.shared.fire(.appLaunchLate)`

### 调度与注册
- 管理器在首次触发时自动加载所有模块的清单并注册任务。
- 按时机聚合、按优先级降序稳定排序、逐个同步执行。
- 基于 `residency` 决定任务的持有与释放。

## Topics

### 核心协议与模型
- ``StartupTask``
- ``StartupTaskPhase``
- ``StartupTaskPriority``
- ``StartupTaskResidency``
- ``StartupTaskContext``
- ``StartupTaskResult``
- ``TaskDescriptor``

### 调度器与注册
- ``StartupTaskManager``
- 清单解析：``ManifestDiscovery``

### 示例
- ``PushNotificationInitTask``
- ``ScreenshotTipTask``
- ``UpgradePromptTask``
