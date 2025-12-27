// Copyright © 2025 Coo. All rights reserved.

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

// MARK: - Debug Helper
// 用于在编译期输出日志，方便调试路径问题
struct DebugDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}

// MARK: - Helper

enum MacroHelper {
    /// 提取模块名称
    /// 策略：
    /// 1. 显式传参：@RegisterModule("MyModule")
    /// 2. 文件路径推断：从 Sources/{Module} 推断
    static func extractModuleName(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> String {
        // 1. 尝试从参数获取
        if let args = node.arguments?.as(LabeledExprListSyntax.self),
           let first = args.first,
           let str = first.expression.as(StringLiteralExprSyntax.self) {
            let name = str.segments.first?.as(StringSegmentSyntax.self)?.content.text ?? ""
            if !name.isEmpty {
                return name
            }
        }
        
        // 2. 尝试从文件路径推断
        if let filePath = context.location(of: node)?.file.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text {
            // [Debug] 输出真实的文件路径到编译器警告中，方便查看
            context.diagnose(Diagnostic(
                node: node,
                message: DebugDiagnostic(
                    message: "🔍 [CooDebug] Real FilePath: \(filePath)",
                    diagnosticID: MessageID(domain: "CooMacros", id: "path_debug"),
                    severity: .warning
                )
            ))
            
            return extractModuleNameFromPath(filePath)
        }
        
        // 无法推断，返回空字符串（后续可能会导致运行时类查找失败，但编译期不报错）
        return ""
    }
    
    /// 从文件路径提取模块名
    private static func extractModuleNameFromPath(_ path: String) -> String {
        let components = path.split(separator: "/")
        
        // 常见模式匹配
        // Pattern: Sources/{Module}/...
        if let sourcesIndex = components.firstIndex(of: "Sources"),
           sourcesIndex + 1 < components.count {
            return String(components[sourcesIndex + 1])
        }
        
        // Pattern: {Module}/Sources/... (反向结构)
        if let sourcesIndex = components.firstIndex(of: "Sources"),
           sourcesIndex > 0 {
            return String(components[sourcesIndex - 1])
        }
        
        // Fallback: 使用当前目录名
        return components.last?.replacingOccurrences(of: ".swift", with: "") ?? ""
    }
}

// MARK: - Macros

/// 注册模块宏 (Member Macro)
public struct CORegisterModuleMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        var typeName = ""
        
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            typeName = enumDecl.name.text
        } else {
            return []
        }
        let moduleName = MacroHelper.extractModuleName(from: node, in: context)
        
        // 如果没有模块名，仅使用类名（运行时可能需要 @objc 配合）
        let finalName = moduleName.isEmpty ? typeName : "\(moduleName).\(typeName)"
        
        return [
            """
            @_used
            @_section("__DATA,__coo_mod")
            static let _coo_mod_entry: (StaticString) = (
                "\(raw: finalName)"
            )
            """
        ]
    }
}

/// 注册服务宏 (Member Macro)
public struct CORegisterServiceMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        var typeName = ""
        
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            /// 判断当前声明的目标对象的类型，这里是struct
            typeName = structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            /// 判断当前声明的目标对象的类型，这里是class
            typeName = classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            /// 判断当前声明的目标对象的类型，这里是enum
            typeName = enumDecl.name.text
        } else {
            return []
        }
        let moduleName = MacroHelper.extractModuleName(from: node, in: context)
        
        let finalName = moduleName.isEmpty ? typeName : "\(moduleName).\(typeName)"
        
        return [
            """
            @_used
            @_section("__DATA,__coo_svc")
            static let _coo_svc_entry: (StaticString) = (
                "\(raw: finalName)"
            )
            """
        ]
    }
}

@main
struct CooOrchestratorPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CORegisterModuleMacro.self,
        CORegisterServiceMacro.self,
    ]
}
