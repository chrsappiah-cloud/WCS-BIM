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
