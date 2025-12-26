import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import CooOrchestrator
import Testing
import Foundation

#if canImport(CooOrchestratorMacros)
// 引入宏的实现类
import CooOrchestratorMacros
#endif

final class CooOrchestratorTests: XCTestCase {
    
    func testExpansionLogic() throws {
        // 这里定义的 testMacros 是关键，它把宏名字映射到你的实现类
        let testMacros: [String: Macro.Type] = [
            "OrchService": CORegisterServiceMacro.self
        ]
#if canImport(CooOrchestratorMacros)
        // 调用此函数会触发 CORegisterServiceMacro.expansion
        assertMacroExpansion(
            """
            @OrchService
            final class TestServiceA: COService {
                static func register(in registry: CooOrchestrator.CORegistry<TestServiceA>) {
                    print("模块执行了\(type(of: self))")
                }
                init() {}
            }
            """,
            expandedSource: """
            @OrchService("CooOrchestratorTests")
            final class TestServiceA: COService {
                static func register(in registry: CooOrchestrator.CORegistry<TestServiceA>) {
                    print("模块执行了\(type(of: self))")
                }
                init() {}
                @_used
                @_section("__DATA,__coo_svc")
                static let _coo_svc_entry: (StaticString) = (
                    "CooOrchestratorTests.TestServiceA"
                )
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}


@OrchService
final class TestServiceA: COService {
    static func register(in registry: CooOrchestrator.CORegistry<TestServiceA>) {
        print("模块执行了\(type(of: self))")
    }
    init() {}
}
