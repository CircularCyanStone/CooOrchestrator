import Foundation
import CooAppStartupTask

public final class EnvironmentDemoTask: NSObject, AppLifecycleTask {
    public static let id: String = "env.demo"
    public static let phase: AppLifecyclePhase = .didFinishLaunchBegin
    public static let priority: LifecycleTaskPriority = .init(rawValue: 50)
    public static let residency: LifecycleTaskRetentionPolicy = .destroy
    
    // 协议变更：init 必须无参
    public required override init() {
        super.init()
    }

    // 协议变更：run 接收 context 参数，支持 throws
    public func run(context: LifecycleContext) throws -> LifecycleResult {
        let bundle = context.environment.bundle
        let identifier = bundle.bundleIdentifier ?? "unknown.bundle"
        let version = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
        let build = (bundle.infoDictionary?["CFBundleVersion"] as? String) ?? "0"

        let msg: String
        if let url = bundle.url(forResource: "EnvDemo", withExtension: "plist", subdirectory: "startupTask"),
           let data = try? Data(contentsOf: url),
           let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = obj as? [String: Any],
           let welcome = dict["WelcomeMessage"] as? String {
            msg = welcome
        } else if let path = bundle.paths(forResourcesOfType: "plist", inDirectory: nil).first(where: { $0.hasSuffix("/startupTask/EnvDemo.plist") }),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                  let dict = obj as? [String: Any],
                  let welcome = dict["WelcomeMessage"] as? String {
            msg = welcome
        } else {
            msg = "EnvDemo.plist not found"
        }

        // 依然可以调用 Logging，但实际上 Manager 也会记录一次
        Logging.logTask(
            "EnvironmentDemoTask",
            phase: Self.phase,
            success: true,
            message: "bundle=\(identifier) v\(version)(\(build)) msg=\(msg)",
            cost: 0
        )
        return .ok
    }
}
