//
//  CORegistrationMacros.h
//  CooOrchestrator
//
//  Created by Coo on 2025/12/25.
//  Copyright © 2025 Coo. All rights reserved.
//
//  文件功能描述：提供 C/ObjC 宏，用于在编译期将模块或服务类名注入到 Mach-O 的指定 Section 中。
//  使用指南：
//  1. 在您的模块中创建一个 .m 文件（例如 COModuleRegistration.m）。
//  2. 引入此头文件。
//  3. 使用宏注册您的 Swift 类（需确保 Swift 类有 @objc 标记或继承自 NSObject 以便运行时可见，
//     或者仅依赖字符串反射，COSectionDiscovery 使用 NSClassFromString，所以 Swift 类必须可见）。
//
//  示例：
//  #import "CORegistrationMacros.h"
//  CO_REGISTER_MODULE(MySwiftModule)
//  CO_REGISTER_SERVICE(MySwiftService)
//

#ifndef CORegistrationMacros_h
#define CORegistrationMacros_h

// 核心宏：将 entry 存储在 __DATA 段的指定 section 中
// __attribute__((used)) 确保即使不被引用也不会被链接器优化掉
// section 格式：segment,section
#define CO_DATA_SECTION(sectname) __attribute__((used, section("__DATA," sectname)))

// 注册模块 (COServiceSource)
// 参数：modulename (Swift模块命名空间|target名称|framework名称), classname (模块类型名称)
// 原理：生成变量名 __coo_mod_Module_Class，存储字符串 "Module.Class"
#define CO_REGISTER_MODULE(modulename, classname) \
    CO_DATA_SECTION("__coo_mod") \
    static const char *__coo_mod_##modulename##_##classname = #modulename "." #classname;

// 注册服务 (COService)
// 参数：modulename (Swift模块命名空间|target名称|framework名称), classname (模块类型名称)
#define CO_REGISTER_SERVICE(modulename, classname) \
    CO_DATA_SECTION("__coo_svc") \
    static const char *__coo_svc_##modulename##_##classname = #modulename "." #classname;

#endif /* CORegistrationMacros_h */
