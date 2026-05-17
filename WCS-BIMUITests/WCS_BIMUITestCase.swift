//
//  WCS_BIMUITestCase.swift
//  WCS-BIMUITests
//

import XCTest

class WCS_BIMUITestCase: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()

        let loading = app.otherElements["bootstrap.loading"]
        if loading.waitForExistence(timeout: 3) {
            XCTAssertTrue(
                loading.waitForNonExistence(timeout: 30),
                "SwiftData bootstrap timed out on loading screen"
            )
        }

        if app.staticTexts["Data Store Unavailable"].waitForExistence(timeout: 1) {
            XCTFail("SwiftData bootstrap failed — Data Store Unavailable screen is showing")
        }

        XCTAssertTrue(
            waitForShell(app),
            "App shell did not load (check SwiftData bootstrap)"
        )
        return app
    }

    @MainActor
    func waitForShell(_ app: XCUIApplication, timeout: TimeInterval = 45) -> Bool {
        if app.tabBars.buttons["Projects"].waitForExistence(timeout: timeout) {
            return true
        }
        return app.textFields["project.nameField"].waitForExistence(timeout: 5)
    }

    @MainActor
    @discardableResult
    func createProject(named name: String, in app: XCUIApplication) -> String {
        let unique = "\(name) \(UUID().uuidString.prefix(6))"
        app.tabBars.buttons["Projects"].tap()
        let nameField = app.textFields["project.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText(unique)
        dismissKeyboard(in: app)
        app.buttons["project.addButton"].tap()
        XCTAssertTrue(projectRow(named: unique, in: app).waitForExistence(timeout: 10))
        return unique
    }

    @MainActor
    func projectRow(named name: String, in app: XCUIApplication) -> XCUIElement {
        if app.staticTexts[name].exists { return app.staticTexts[name] }
        return app.cells.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    @MainActor
    func openProject(named name: String, in app: XCUIApplication) {
        selectTab("Projects", in: app)
        let row = projectRow(named: name, in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
    }

    @MainActor
    func aiPromptField(in app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(
            app.navigationBars["AI Assistant"].waitForExistence(timeout: 10),
            "AI Assistant screen did not load"
        )
        let candidates: [XCUIElement] = [
            app.textFields["ai.promptField"],
            app.textViews["ai.promptField"],
            app.descendants(matching: .any)["ai.promptField"],
            app.textFields["AI prompt"],
            app.textFields.element(
                matching: NSPredicate(format: "placeholderValue CONTAINS[c] 'massing'")
            )
        ]
        for element in candidates where element.waitForExistence(timeout: 2) {
            return element
        }
        XCTFail("AI prompt field not found")
        return app.textFields.firstMatch
    }

    @MainActor
    func tabIsAvailable(_ title: String, in app: XCUIApplication) -> Bool {
        if app.tabBars.buttons[title].exists { return true }
        guard app.tabBars.buttons["More"].waitForExistence(timeout: 2) else { return false }
        app.tabBars.buttons["More"].tap()
        let found = app.buttons[title].waitForExistence(timeout: 2)
            || app.staticTexts[title].waitForExistence(timeout: 1)
        if app.tabBars.buttons["Projects"].exists {
            app.tabBars.buttons["Projects"].tap()
        }
        return found
    }

    @MainActor
    func selectTab(_ title: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[title]
        if tab.waitForExistence(timeout: 3) {
            tab.tap()
            return
        }

        let more = app.tabBars.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 8), "Tab \(title) not visible and More tab missing")
        more.tap()

        let overflowButton = app.buttons[title]
        if overflowButton.waitForExistence(timeout: 5) {
            overflowButton.tap()
            return
        }

        let overflowLabel = app.staticTexts[title]
        XCTAssertTrue(overflowLabel.waitForExistence(timeout: 5), "Tab \(title) not in overflow menu")
        overflowLabel.tap()
    }

    @MainActor
    func dismissKeyboard(in app: XCUIApplication) {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["Return"].tap()
        }
    }
}
