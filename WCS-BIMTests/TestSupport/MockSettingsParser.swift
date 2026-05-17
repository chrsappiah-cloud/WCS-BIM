import Foundation
@testable import WCS_BIM

final class MockSettingsParser: SettingsJSONParsing {
    var parseResult: [String: String]?

    func parse(_ json: String) -> [String: String]? {
        parseResult
    }
}
