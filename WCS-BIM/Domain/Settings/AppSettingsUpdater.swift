import Foundation

/// Merges JSON settings into persisted user preferences (deterministic, mock-friendly).
final class AppSettingsUpdater: @unchecked Sendable {
    static let mergedSettingsKey = "wcs.userdata"

    static let knownKeys = [
        "openAIApiKey",
        "cloudKitEnabled",
        "designStyle",
        "defaultProgram"
    ]

    private let parser: SettingsJSONParsing
    private let defaults: UserDefaultsStoring

    init(jsonParser: SettingsJSONParsing, standard: UserDefaultsStoring) {
        self.parser = jsonParser
        self.defaults = standard
    }

    func updateSettings(fromJSON json: String) {
        guard let newSettings = parser.parse(json) else { return }
        if var settings = defaults.object(forKey: Self.mergedSettingsKey) as? [String: String] {
            settings.merge(newSettings) { _, new in new }
            defaults.set(settings, forKey: Self.mergedSettingsKey)
        } else {
            defaults.set(newSettings, forKey: Self.mergedSettingsKey)
        }
        mirrorKnownKeysToStandardDefaults()
    }

    /// Copies merged values onto keys read by `@AppStorage` in the UI.
    func mirrorKnownKeysToStandardDefaults() {
        guard let settings = defaults.object(forKey: Self.mergedSettingsKey) as? [String: String] else {
            return
        }
        for key in Self.knownKeys {
            if let value = settings[key] {
                defaults.set(value, forKey: key)
            }
        }
    }

    func mergedSettings() -> [String: String] {
        defaults.object(forKey: Self.mergedSettingsKey) as? [String: String] ?? [:]
    }
}
