//
//  WCS_BIMUITestsLaunchTests.swift
//  WCS-BIMUITests
//
//  Created by Christopher Appiah-Thompson  on 17/5/2026.
//

import XCTest

final class WCS_BIMUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()

        XCTAssertTrue(
            app.tabBars.buttons["Projects"].waitForExistence(timeout: 45)
                || app.textFields["project.nameField"].waitForExistence(timeout: 10)
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
