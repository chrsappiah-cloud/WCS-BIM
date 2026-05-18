//
//  SubscriptionAccessTests.swift
//  WCS-BIMTests
//

import XCTest
@testable import WCS_BIM

@MainActor
final class SubscriptionAccessTests: XCTestCase {

    func testTierOrdering() {
        XCTAssertTrue(SubscriptionTier.pro > SubscriptionTier.free)
        XCTAssertTrue(SubscriptionTier.enterprise > SubscriptionTier.team)
    }

    func testProductIDMapping() {
        XCTAssertEqual(SubscriptionTier.from(productID: SubscriptionProductIDs.proMonthly), .pro)
        XCTAssertEqual(SubscriptionTier.from(productID: "unknown"), nil)
    }

    func testAdminOverrideRaisesTier() {
        let controller = SubscriptionAccessController()
        controller.setAdminOverride(.team)
        XCTAssertEqual(controller.activeTier, .team)
        controller.setAdminOverride(nil)
        XCTAssertEqual(controller.activeTier, .free)
    }

    func testFeatureGating() {
        let controller = SubscriptionAccessController()
        XCTAssertFalse(controller.hasFeature(.exportIFC))
        controller.setAdminOverride(.pro)
        XCTAssertTrue(controller.hasFeature(.exportIFC))
        XCTAssertFalse(controller.hasFeature(.cloudKitSync))
        controller.setAdminOverride(.team)
        XCTAssertTrue(controller.hasFeature(.cloudKitSync))
    }
}
