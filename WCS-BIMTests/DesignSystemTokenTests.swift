//
//  DesignSystemTokenTests.swift
//  WCS-BIMTests
//

import SwiftUI
import XCTest
@testable import WCS_BIM

final class DesignSystemTokenTests: XCTestCase {

    func testSemanticColorsResolve() {
        _ = WCSColor.primary
        _ = WCSColor.secondary
        _ = WCSColor.highlight
        _ = WCSColor.success
        _ = WCSColor.error
    }

    func testLuxePaletteResolves() {
        _ = WCSLuxePalette.cocoa
        _ = WCSLuxePalette.espresso
        _ = WCSLuxePalette.diamond
        _ = WCSLuxePalette.champagne
        _ = WCSLuxePalette.gold
    }

    func testBIMRouteTabsMatchShell() {
        XCTAssertEqual(WCSRouteTab.bimWorkflow.count, 5)
        XCTAssertEqual(WCSRouteTab.bimWorkflow.first?.accessibilityIdentifier, "tab.projects")
        XCTAssertTrue(WCSRouteTab.bimWorkflow.contains { $0.id == "more" })
    }

    func testLearningRouteTabsAll() {
        XCTAssertEqual(WCSRouteTab.all.count, 5)
        XCTAssertEqual(WCSRouteTab.all[0].title, "Home")
        XCTAssertEqual(WCSRouteTab.learningShell.count, WCSRouteTab.all.count)
    }

    func testInspectorParamIdentity() {
        let param = InspectorParam(key: "Width", value: "200")
        XCTAssertEqual(param.id, "Width")
        XCTAssertEqual(param.key, "Width")
        XCTAssertEqual(param.value, "200")
    }

    func testStatusChipTonesAreDistinct() {
        XCTAssertNotEqual(
            String(describing: StatusChip.Tone.pending),
            String(describing: StatusChip.Tone.resolved)
        )
    }
}
