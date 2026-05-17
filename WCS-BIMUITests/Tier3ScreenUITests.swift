//
//  Tier3ScreenUITests.swift
//  WCS-BIMUITests
//
//  Tier 3 — Screen-level UI coverage (nightly device matrix).
//

import XCTest

final class Tier3ScreenUITests: WCS_BIMUITestCase {

    @MainActor
    func testProjectsScreen() throws {
        let app = launchApp()
        selectTab("Projects", in: app)
        XCTAssertTrue(app.textFields["project.nameField"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["project.addButton"].exists)
    }

    @MainActor
    func testSiteScreen() throws {
        let app = launchApp()
        selectTab("Site", in: app)
        XCTAssertTrue(app.navigationBars["Site Capture"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testAREmptyOrLoadedScreen() throws {
        let app = launchApp()
        selectTab("AR", in: app)
        XCTAssertTrue(
            app.staticTexts["No Project"].waitForExistence(timeout: 8)
            || app.navigationBars["AR Site"].waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testAIScreen() throws {
        let app = launchApp()
        selectTab("AI", in: app)
        XCTAssertTrue(aiPromptField(in: app).exists)
        XCTAssertTrue(app.buttons["ai.generateButton"].exists)
    }

    @MainActor
    func testExportEmptyScreen() throws {
        let app = launchApp()
        selectTab("Export", in: app)
        XCTAssertTrue(app.navigationBars["Export Center"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testSettingsScreen() throws {
        let app = launchApp()
        selectTab("Settings", in: app)
        XCTAssertTrue(app.buttons["Install all design programs"].waitForExistence(timeout: 10))
    }
}
