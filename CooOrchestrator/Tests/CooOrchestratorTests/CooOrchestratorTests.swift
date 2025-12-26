import Testing
@testable import CooOrchestrator

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    
    final class TestServiceA: COService {
        static func register(in registry: CooOrchestrator.CORegistry<TestServiceA>) {
            print("模块已注册")
        }
    }
    
    print("example 测试 run")
    
}
