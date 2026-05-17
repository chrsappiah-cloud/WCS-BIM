import Foundation

/// Production JSON parser for `AppSettingsUpdater`.
struct SettingsJSONParser: SettingsJSONParsing {
    func parse(_ json: String) -> [String: String]? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        var result: [String: String] = [:]
        for (key, value) in object {
            if let string = value as? String {
                result[key] = string
            } else if let flag = value as? Bool {
                result[key] = flag ? "true" : "false"
            } else if let number = value as? NSNumber {
                result[key] = number.stringValue
            }
        }
        return result.isEmpty ? nil : result
    }
}
