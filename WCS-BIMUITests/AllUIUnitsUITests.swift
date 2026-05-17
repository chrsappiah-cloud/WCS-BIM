//
//  AllUIUnitsUITests.swift
//  WCS-BIMUITests
//
//  End-to-end pass across all six app units (tabs) in one session.
//

import XCTest

final class AllUIUnitsUITests: WCS_BIMUITestCase {

    @MainActor
    func testAllUIUnitsEndToEnd() throws {
        let app = launchApp()

        // Projects
        selectTab("Projects", in: app)
        XCTAssertTrue(app.textFields["project.nameField"].exists)
        createProject(named: "E2E", in: app)

        // Site
        selectTab("Site", in: app)
        XCTAssertTrue(app.navigationBars["Site Capture"].waitForExistence(timeout: 10))

        // AR (project from create step)
        selectTab("AR", in: app)
        XCTAssertTrue(app.navigationBars["AR Site"].waitForExistence(timeout: 10))

        // AI
        selectTab("AI", in: app)
        let prompt = aiPromptField(in: app)
        prompt.tap()
        prompt.typeText("Massing study")
        dismissKeyboard(in: app)
        app.buttons["ai.generateButton"].tap()
        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'massing' OR label CONTAINS[c] 'offline' OR label CONTAINS[c] 'AI'")
            ).firstMatch.waitForExistence(timeout: 20)
        )

        // Export
        selectTab("Export", in: app)
        XCTAssertTrue(app.buttons["export.ifc"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["export.cobie"].exists)
        XCTAssertTrue(app.buttons["export.pdf"].exists)
        XCTAssertTrue(app.buttons["export.dwg"].exists)

        // Settings + design pack
        selectTab("Settings", in: app)
        XCTAssertTrue(app.buttons["settings.installPrograms"].waitForExistence(timeout: 10))
        app.buttons["settings.installPrograms"].tap()
        XCTAssertTrue(app.staticTexts["settings.installMessage"].waitForExistence(timeout: 10))
    }
}
