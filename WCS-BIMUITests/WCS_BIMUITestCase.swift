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
        if ["AI", "Settings"].contains(title) {
            return true
        }
        tapTabBarButton("More", in: app)
        let found = app.buttons[title].waitForExistence(timeout: 2)
            || app.staticTexts[title].waitForExistence(timeout: 1)
        if app.tabBars.buttons["Projects"].exists {
            tapTabBarButton("Projects", in: app)
        }
        return found
    }

    @MainActor
    func tapTabBarButton(_ title: String, in app: XCUIApplication) {
        let button = app.tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Tab bar button missing: \(title)")
        if button.isHittable {
            button.tap()
            return
        }

        let positions: [String: CGFloat] = [
            "Projects": 0.1,
            "Site": 0.3,
            "AR": 0.5,
            "Export": 0.7,
            "More": 0.9
        ]
        let x = positions[title] ?? 0.5
        app.tabBars.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: x, dy: 0.5)
        ).tap()
    }

    @MainActor
    func popToTabBar(in app: XCUIApplication) {
        for _ in 0..<8 {
            if app.tabBars.buttons["Projects"].waitForExistence(timeout: 1) {
                return
            }
            if app.tabBars.buttons["More"].exists {
                return
            }
            let backButtons = app.navigationBars.buttons
            guard backButtons.count > 0 else { break }
            let back = backButtons.element(boundBy: 0)
            guard back.exists, back.isHittable else { break }
            back.tap()
        }
    }

    @MainActor
    func selectTab(_ title: String, in app: XCUIApplication) {
        popToTabBar(in: app)
        let tab = app.tabBars.buttons[title]
        if tab.waitForExistence(timeout: 3) {
            tapTabBarButton(title, in: app)
            if title == "Export",
               !app.descendants(matching: .any)["export.screen"].waitForExistence(timeout: 3) {
                tapTabBarButton("Projects", in: app)
                tapTabBarButton("Export", in: app)
                if !app.buttons["export.ifc"].waitForExistence(timeout: 3) {
                    tapTabBarButton("Projects", in: app)
                    let field = app.textFields["project.nameField"]
                    XCTAssertTrue(field.waitForExistence(timeout: 8))
                    field.tap()
                    field.typeText("Recovered Export \(UUID().uuidString.prefix(6))")
                    dismissKeyboard(in: app)
                    app.buttons["project.addButton"].tap()
                    tapTabBarButton("Export", in: app)
                }
            }
            return
        }

        // Reset the overflow navigation stack before opening another overflow
        // destination. Tapping More while it is already selected leaves the
        // previous child screen active on physical devices.
        let projects = app.tabBars.buttons["Projects"]
        if projects.waitForExistence(timeout: 2) {
            tapTabBarButton("Projects", in: app)
        }

        let more = app.tabBars.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 8), "Tab \(title) not visible and More tab missing")
        tapTabBarButton("More", in: app)

        // iOS preserves the selected More destination's NavigationStack.
        // Unwind it until the overflow list exposes the requested destination.
        for _ in 0..<8 {
            let overflowButton = app.buttons[title].firstMatch
            if overflowButton.exists, overflowButton.isHittable {
                overflowButton.tap()
                return
            }

            let overflowLabel = app.staticTexts[title].firstMatch
            if overflowLabel.exists, overflowLabel.isHittable {
                overflowLabel.tap()
                return
            }

            let overflowCell = app.cells.containing(
                NSPredicate(format: "label CONTAINS[c] %@", title)
            ).firstMatch
            if overflowCell.exists, overflowCell.isHittable {
                overflowCell.tap()
                return
            }

            let back = app.navigationBars.buttons.firstMatch
            if back.exists, back.isHittable {
                back.tap()
            }
        }
        XCTFail("Tab \(title) not in overflow menu")
    }

    @MainActor
    func dismissKeyboard(in app: XCUIApplication) {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["Return"].tap()
        }
    }

    @MainActor
    @discardableResult
    func waitForElement(
        _ id: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[id]
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing UI: \(id)")
        return element
    }

    @MainActor
    func openSettings(in app: XCUIApplication) {
        selectTab("Settings", in: app)
        _ = waitForElement("settings.screen", in: app, timeout: 12)
    }

    @MainActor
    func openSettingsLink(_ title: String, in app: XCUIApplication) {
        openSettings(in: app)
        let identifiers: [String: String] = [
            "My subscription": "settings.subscription",
            "Admin access": "settings.adminAccess",
            "Luxe dashboard (chocolate)": "settings.luxeDashboard",
            "Navigation components": "settings.navigationShowcase",
            "Learning tab shell (5 tabs)": "settings.learningShell",
            "Field Systems (sensors & capture)": "settings.fieldSystems"
        ]
        // Forms retain their previous scroll position when revisited. Return to
        // the top, then scan downward for the requested destination.
        for _ in 0..<8 {
            app.swipeDown()
        }
        for _ in 0..<12 {
            if let id = identifiers[title] {
                let identifiedLink = app.buttons[id].firstMatch
                if identifiedLink.exists, identifiedLink.isHittable {
                    identifiedLink.tap()
                    return
                }
            }
            let link = app.buttons[title].firstMatch
            if link.exists, link.isHittable {
                link.tap()
                return
            }
            let text = app.staticTexts[title].firstMatch
            if text.exists, text.isHittable {
                text.tap()
                return
            }
            app.swipeUp()
        }
        XCTFail("Settings link not found: \(title)")
    }

    @MainActor
    func openFullSiteCapture(in app: XCUIApplication) {
        selectTab("Site", in: app)
        XCTAssertTrue(
            app.otherElements["site.capture.screen"].waitForExistence(timeout: 10)
                || app.maps.firstMatch.waitForExistence(timeout: 8)
        )

        let linkCandidates: [XCUIElement] = [
            app.buttons["site.capture.fullLink"],
            app.buttons["Full site capture"],
            app.staticTexts["Full site capture"]
        ]
        var opened = false
        for link in linkCandidates where link.waitForExistence(timeout: 3) {
            link.tap()
            opened = true
            break
        }

        if opened {
            XCTAssertTrue(
                app.otherElements["site.capture.form"].waitForExistence(timeout: 12)
                    || app.navigationBars["Full Site Capture"].waitForExistence(timeout: 12),
                "Site capture form did not load"
            )
            for _ in 0..<4 where !app.buttons["site.capture.camera"].exists {
                app.swipeUp()
            }
            XCTAssertTrue(
                app.buttons["site.capture.camera"].waitForExistence(timeout: 8),
                "Site capture camera control not found"
            )
            popToTabBar(in: app)
        }
    }

    @MainActor
    func exerciseExportButtons(in app: XCUIApplication) {
        selectTab("Export", in: app)
        _ = waitForElement("export.screen", in: app)
        for id in ["export.ifc", "export.cobie", "export.pdf", "export.dwg"] {
            let button = app.buttons[id]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing export: \(id)")
            button.tap()
        }
    }

    @MainActor
    func unlockAdminPanel(in app: XCUIApplication, pin: String = "wcs-admin") {
        openSettingsLink("Admin access", in: app)
        _ = waitForElement("admin.screen", in: app)
        let pinField = app.secureTextFields["admin.pinField"]
        if pinField.waitForExistence(timeout: 3) {
            pinField.tap()
            pinField.typeText(pin)
            dismissKeyboard(in: app)
            app.buttons["admin.unlock"].tap()
        }
        XCTAssertTrue(
            app.buttons["admin.lock"].waitForExistence(timeout: 5)
                || app.buttons["admin.applyOverride"].waitForExistence(timeout: 5),
            "Admin panel did not unlock"
        )
    }
}
