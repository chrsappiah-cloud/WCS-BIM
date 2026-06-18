//
//  SiteLocationValuationUITests.swift
//  WCS-BIMUITests
//
//  End-to-end flows for manual/search/live site location and valuation.
//

import XCTest

final class SiteLocationValuationUITests: WCS_BIMUITestCase {

    @MainActor
    func testManualLocationValuationE2E() throws {
        let app = launchApp()
        let projectName = createProject(named: "Valuation Manual E2E", in: app)
        openProjectSiteLocationPanel(in: app, projectName: projectName)

        fillManualLocation(
            address: "Bennelong Point, Sydney NSW",
            latitude: "-33.85678",
            longitude: "151.21530",
            in: app
        )

        let apply = app.buttons["site.location.manualApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 8))
        apply.tap()

        let value = runSiteValuation(in: app)
        XCTAssertFalse(value.label.isEmpty)
        XCTAssertNotEqual(value.label, "—")

        XCTAssertTrue(
            app.staticTexts["site.location.savedCoordinates"].waitForExistence(timeout: 5)
                || app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS '-33.856'")
                ).firstMatch.waitForExistence(timeout: 5)
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Manual location valuation E2E"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSearchLocationValuationE2E() throws {
        let app = launchApp()
        let projectName = createProject(named: "Valuation Search E2E", in: app)
        openProjectSiteLocationPanel(in: app, projectName: projectName)

        selectLocationMode("Search", in: app)

        let searchField = app.textFields["site.location.searchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 8))
        searchField.tap()
        searchField.typeText("Sydney Opera House")
        dismissKeyboard(in: app)

        app.buttons["site.location.searchButton"].tap()

        let result = app.buttons["site.location.searchResult"]
        XCTAssertTrue(
            result.waitForExistence(timeout: 20),
            "MapKit search did not return a selectable result"
        )
        result.tap()

        let value = app.staticTexts["site.location.valuationValue"]
        XCTAssertTrue(
            value.waitForExistence(timeout: 15),
            "Valuation did not update after search selection"
        )
        XCTAssertFalse(value.label.isEmpty)
    }

    @MainActor
    func testLiveLocatorUIE2E() throws {
        let app = launchApp()
        let projectName = createProject(named: "Valuation Live E2E", in: app)
        openProjectSiteLocationPanel(in: app, projectName: projectName)

        selectLocationMode("Live", in: app)

        XCTAssertTrue(
            app.otherElements["site.location.liveMap"].waitForExistence(timeout: 8)
                || app.maps.firstMatch.waitForExistence(timeout: 8),
            "Live locator map missing"
        )
        XCTAssertTrue(
            app.otherElements["site.location.locatorHeader"].waitForExistence(timeout: 8),
            "Locator header missing"
        )
        XCTAssertTrue(
            app.otherElements["site.location.gpsIndicator"].waitForExistence(timeout: 8)
                || app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'GPS'")
                ).firstMatch.waitForExistence(timeout: 8),
            "GPS indicator missing"
        )
        XCTAssertTrue(
            app.switches["site.location.autoValuationToggle"].waitForExistence(timeout: 8)
                || app.staticTexts["Auto-valuation when property is identified"].waitForExistence(timeout: 8),
            "Auto-valuation toggle missing"
        )

        let enableButton = app.buttons["site.location.requestGPS"]
        if enableButton.waitForExistence(timeout: 3) {
            enableButton.tap()
        }

        XCTAssertTrue(
            app.buttons["site.location.runValuation"].waitForExistence(timeout: 8),
            "Run valuation control missing in live mode"
        )
    }

    @MainActor
    func testLocationModeSwitchingE2E() throws {
        let app = launchApp()
        let projectName = createProject(named: "Valuation Modes E2E", in: app)
        openProjectSiteLocationPanel(in: app, projectName: projectName)

        for mode in ["Live", "Search", "Manual"] {
            selectLocationMode(mode, in: app)
            switch mode {
            case "Live":
                XCTAssertTrue(
                    app.otherElements["site.location.liveMap"].waitForExistence(timeout: 5)
                        || app.maps.firstMatch.exists
                )
            case "Search":
                XCTAssertTrue(app.textFields["site.location.searchField"].waitForExistence(timeout: 5))
            case "Manual":
                XCTAssertTrue(app.textFields["site.location.manualLatitude"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.textFields["site.location.manualLongitude"].waitForExistence(timeout: 5))
            default:
                break
            }
        }
    }

    @MainActor
    func testFullSiteCaptureLocationPanelE2E() throws {
        let app = launchApp()
        createProject(named: "Full Capture E2E", in: app)

        selectTab("Site", in: app)
        XCTAssertTrue(
            app.otherElements["site.capture.screen"].waitForExistence(timeout: 10)
                || app.maps.firstMatch.waitForExistence(timeout: 8)
        )

        let link = app.buttons["site.capture.fullLink"]
        XCTAssertTrue(link.waitForExistence(timeout: 8))
        link.tap()

        XCTAssertTrue(
            app.otherElements["site.capture.form"].waitForExistence(timeout: 12)
                || app.navigationBars["Full Site Capture"].waitForExistence(timeout: 12)
        )

        scrollToSiteLocationPanel(in: app)
        XCTAssertTrue(
            locationModeButton("Manual", in: app).waitForExistence(timeout: 8),
            "Location panel not present in full site capture"
        )

        selectLocationMode("Manual", in: app)
        fillManualLocation(
            address: "1 Macquarie Street, Sydney",
            latitude: "-33.8619",
            longitude: "151.2133",
            in: app
        )
        app.buttons["site.location.manualApply"].tap()
        _ = runSiteValuation(in: app)
    }
}
