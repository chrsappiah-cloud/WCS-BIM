//
//  DesignSystemUITests.swift
//  WCS-BIMUITests
//
//  Smoke coverage for design-system accessibility identifiers.
//

import XCTest

final class DesignSystemUITests: WCS_BIMUITestCase {

    @MainActor
    func testInspectorSheetIdentifiers() throws {
        let app = launchApp()
        let projectName = createProject(named: "Inspector UI", in: app)
        openProject(named: projectName, in: app)

        app.buttons["project.editParameters"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["Inspector_Sheet"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.textFields["Inspector_Param_Name"].waitForExistence(timeout: 5))
        let cancel = app.buttons["Inspector_Cancel"]
        if cancel.waitForExistence(timeout: 3) {
            cancel.tap()
        } else {
            app.buttons["Cancel"].tap()
        }
    }

    @MainActor
    func testProjectsHeroAndPrimaryAdd() throws {
        let app = launchApp()
        XCTAssertTrue(
            app.descendants(matching: .any)["projects.heroCard"].waitForExistence(timeout: 8)
                || app.staticTexts["ArchFusion BIM"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.buttons["project.addButton"].waitForExistence(timeout: 8)
                || app.buttons["Add"].waitForExistence(timeout: 3)
        )
    }
}
