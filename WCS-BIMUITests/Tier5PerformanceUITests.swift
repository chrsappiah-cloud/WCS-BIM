//
//  Tier5PerformanceUITests.swift
//  WCS-BIMUITests
//
//  Tier 5 — Performance baselines (nightly; non-blocking in PR).
//

import XCTest

final class Tier5PerformanceUITests: WCS_BIMUITestCase {

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("-UITesting")
            app.launchEnvironment["UITESTING"] = "1"
            app.launch()
        }
    }
}
