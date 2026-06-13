//
//  Tier4FeaturesUITests.swift
//  WCS-BIMUITests
//
//  Tier 4 — Subscriptions, admin, field systems, appearance, navigation kit.
//

import XCTest

final class Tier4FeaturesUITests: WCS_BIMUITestCase {

  @MainActor
  func testSubscriptionPanelUI() throws {
    let app = launchApp()
    openSettingsLink("My subscription", in: app)
    _ = waitForElement("subscription.screen", in: app)
    XCTAssertTrue(app.textFields["subscription.emailField"].exists)
    XCTAssertTrue(app.buttons["subscription.applyEmail"].exists)
    XCTAssertTrue(app.buttons["subscription.loadProducts"].exists)
    XCTAssertTrue(app.buttons["subscription.restore"].exists)
  }

  @MainActor
  func testAdminAccessPanelUI() throws {
    let app = launchApp()
    unlockAdminPanel(in: app)
    XCTAssertTrue(app.buttons["admin.applyOverride"].exists)
    XCTAssertTrue(app.buttons["admin.clearOverride"].exists)
    app.buttons["admin.lock"].tap()
    XCTAssertTrue(app.secureTextFields["admin.pinField"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testFieldSystemsPanelUI() throws {
    let app = launchApp()
    createProject(named: "Field UI", in: app)
    openSettingsLink("Field Systems (sensors & capture)", in: app)
    _ = waitForElement("fieldSystems.screen", in: app)
    XCTAssertTrue(app.buttons["fieldSystems.toggleSensors"].exists)
    XCTAssertTrue(app.buttons["fieldSystems.openCamera"].exists)
    XCTAssertTrue(app.textFields["fieldSystems.aiPrompt"].exists)
    XCTAssertTrue(app.buttons["fieldSystems.aiGenerate"].exists)
    app.buttons["fieldSystems.aiGenerate"].tap()
    XCTAssertTrue(
      app.staticTexts["fieldSystems.aiResult"].waitForExistence(timeout: 15)
    )
  }

  @MainActor
  func testAppearanceScreens() throws {
    let app = launchApp()

    openSettingsLink("Luxe dashboard (chocolate)", in: app)
    _ = waitForElement("luxe.home.screen", in: app)
    XCTAssertTrue(app.buttons["luxe.action.newProject"].exists)

    openSettings(in: app)
    openSettingsLink("Navigation components", in: app)
    _ = waitForElement("nav.showcase.screen", in: app)

    openSettings(in: app)
    openSettingsLink("Learning tab shell (5 tabs)", in: app)
    _ = waitForElement("learning.shell", in: app)
    XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    XCTAssertTrue(app.tabBars.buttons["Learn"].exists)
  }

  @MainActor
  func testSiteCaptureCameraAndPicker() throws {
    let app = launchApp()
    createProject(named: "Site UI", in: app)
    openFullSiteCapture(in: app)
    XCTAssertTrue(
      app.buttons["site.capture.photosPicker"].waitForExistence(timeout: 5)
        || app.buttons["Import from library"].waitForExistence(timeout: 5)
    )
  }

  @MainActor
  func testCloudKitAddProjectButton() throws {
    let app = launchApp()
    selectTab("Projects", in: app)
    let cloud = app.buttons["project.addCloudButton"]
    XCTAssertTrue(
      cloud.waitForExistence(timeout: 5) || app.buttons["Add + CloudKit"].waitForExistence(timeout: 3)
    )
  }
}
