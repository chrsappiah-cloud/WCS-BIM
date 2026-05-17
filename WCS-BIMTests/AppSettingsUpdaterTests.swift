//
//  AppSettingsUpdaterTests.swift
//  WCS-BIMTests
//
//  Protocol + mock pattern for deterministic CI unit tests.
//

import XCTest
@testable import WCS_BIM

final class AppSettingsUpdaterTests: XCTestCase {
    private var userDefaults: MockUserDefaults!
    private var settingsUpdater: AppSettingsUpdater!
    private var mockParser: MockSettingsParser!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        mockParser = MockSettingsParser()
        settingsUpdater = AppSettingsUpdater(jsonParser: mockParser, standard: userDefaults)
    }

    func testUpdateSettingsCreatesNewStore() {
        mockParser.parseResult = ["name": "jim", "designStyle": "Airport"]
        settingsUpdater.updateSettings(fromJSON: "{}")

        let expected = ["name": "jim", "designStyle": "Airport"]
        XCTAssertEqual(
            expected as NSDictionary,
            userDefaults.object(forKey: AppSettingsUpdater.mergedSettingsKey) as? NSDictionary
        )
        XCTAssertEqual(userDefaults.object(forKey: "designStyle") as? String, "Airport")
    }

    func testUpdateSettingsMergesExistingStore() {
        userDefaults.set(["name": "ann"], forKey: AppSettingsUpdater.mergedSettingsKey)
        mockParser.parseResult = ["defaultProgram": "Terminal 40,000 m²"]
        settingsUpdater.updateSettings(fromJSON: "{}")

        let stored = userDefaults.object(forKey: AppSettingsUpdater.mergedSettingsKey) as? [String: String]
        XCTAssertEqual(stored?["name"], "ann")
        XCTAssertEqual(stored?["defaultProgram"], "Terminal 40,000 m²")
    }

    func testUpdateSettingsIgnoresInvalidJSON() {
        mockParser.parseResult = nil
        userDefaults.set(["openAIApiKey": "existing"], forKey: AppSettingsUpdater.mergedSettingsKey)
        settingsUpdater.updateSettings(fromJSON: "not-json")

        XCTAssertEqual(
            userDefaults.object(forKey: AppSettingsUpdater.mergedSettingsKey) as? [String: String],
            ["openAIApiKey": "existing"]
        )
    }

    func testProductionParserParsesBooleansAndStrings() {
        let parser = SettingsJSONParser()
        let parsed = parser.parse("""
        {"cloudKitEnabled": true, "designStyle": "Commercial", "defaultProgram": "Office"}
        """)
        XCTAssertEqual(parsed?["cloudKitEnabled"], "true")
        XCTAssertEqual(parsed?["designStyle"], "Commercial")
        XCTAssertEqual(parsed?["defaultProgram"], "Office")
    }
}
