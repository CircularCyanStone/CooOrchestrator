import Foundation
import CooAppStartupTask

@MainActor
public final class EnvironmentDemoTask: NSObject, StartupTask {
    public static let id: String = "env.demo"
    public static let phase: AppStartupPhase = .didFinishLaunchBegin
    public static let priority: StartupTaskPriority = .init(rawValue: 50)
    public static let residency: StartupTaskRetentionPolicy = .destroy​
    

    private let context: StartupTaskContext
    public required init(context: StartupTaskContext) {
        self.context = context
        super.init()
    }

    public func run() -> StartupTaskResult {
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
