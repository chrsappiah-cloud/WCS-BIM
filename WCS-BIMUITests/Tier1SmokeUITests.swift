//
//  Tier1SmokeUITests.swift
//  WCS-BIMUITests
//
//  Tier 1 — Critical smoke (PR gate): shell, core create, export handoff.
//

import XCTest

final class Tier1SmokeUITests: WCS_BIMUITestCase {

    @MainActor
    func testAppShellTabsVisible() throws {
        let app = launchApp()
        for tab in ["Projects", "Site", "AR", "AI", "Export", "Settings"] {
            XCTAssertTrue(tabIsAvailable(tab, in: app), "Missing tab: \(tab)")
        }
    }

    @MainActor
    func testCreateProjectCoreAction() throws {
        let app = launchApp()
        createProject(named: "Smoke Project", in: app)
    }

    @MainActor
    func testExportAfterCreate() throws {
        let app = launchApp()
        createProject(named: "Smoke Export", in: app)
        selectTab("Export", in: app)
        XCTAssertTrue(app.buttons["export.ifc"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["export.cobie"].exists)
    }
}
