import Foundation

/// Parses a JSON object into string settings (testable via mocks).
protocol SettingsJSONParsing: Sendable {
    func parse(_ json: String) -> [String: String]?
}

/// Subset of `UserDefaults` used by settings merge logic (testable via mocks).
protocol UserDefaultsStoring: Sendable {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsStoring {}
