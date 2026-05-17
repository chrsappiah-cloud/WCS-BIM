//
//  Tier2RegressionUITests.swift
//  WCS-BIMUITests
//
//  Tier 2 — Business-critical regression (nightly / release candidate).
//

import XCTest

final class Tier2RegressionUITests: WCS_BIMUITestCase {

    @MainActor
    func testInstallDesignProgramsFlow() throws {
        let app = launchApp()
        selectTab("Settings", in: app)
        app.buttons["settings.installPrograms"].tap()
        XCTAssertTrue(app.staticTexts["settings.installMessage"].waitForExistence(timeout: 10))
        selectTab("Projects", in: app)
        XCTAssertTrue(app.staticTexts["Commercial Hub"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Airport Terminal A"].exists)
    }

    @MainActor
    func testAIAssistantOfflineGenerate() throws {
        let app = launchApp()
        createProject(named: "AI Regression", in: app)
        selectTab("AI", in: app)
        let prompt = aiPromptField(in: app)
        prompt.tap()
        prompt.typeText("Propose massing options")
        app.buttons["ai.generateButton"].tap()
        let response = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'massing' OR label CONTAINS[c] 'offline' OR label CONTAINS[c] 'AI'")
        ).firstMatch
        XCTAssertTrue(response.waitForExistence(timeout: 20))
    }

    @MainActor
    func testARTabWithProject() throws {
        let app = launchApp()
        createProject(named: "AR Regression", in: app)
        selectTab("AR", in: app)
        XCTAssertTrue(app.navigationBars["AR Site"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testProjectWorkspaceNavigation() throws {
        let app = launchApp()
        let projectName = createProject(named: "Workspace Regression", in: app)
        openProject(named: projectName, in: app)
        XCTAssertTrue(app.buttons["Open full workspace"].waitForExistence(timeout: 8))
        app.buttons["Open full workspace"].tap()
        XCTAssertTrue(
            app.navigationBars[projectName].waitForExistence(timeout: 10)
                || app.staticTexts["Overview"].waitForExistence(timeout: 10)
                || app.segmentedControls.firstMatch.waitForExistence(timeout: 10)
        )
    }
}
