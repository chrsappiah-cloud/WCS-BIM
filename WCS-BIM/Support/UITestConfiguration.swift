import Foundation

enum UITestConfiguration {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
            || ProcessInfo.processInfo.environment["UITESTING"] == "1"
    }
}
