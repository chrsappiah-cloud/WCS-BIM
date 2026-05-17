import Foundation
@testable import WCS_BIM

final class MockUserDefaults: UserDefaultsStoring {
    var values: [String: Any?] = [:]

    func object(forKey defaultName: String) -> Any? {
        values[defaultName] ?? nil
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
    }
}
