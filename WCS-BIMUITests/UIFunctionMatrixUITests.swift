//
//  UIFunctionMatrixUITests.swift
//  WCS-BIMUITests
//
//  Displays and exercises every registered UI function (accessibility ID) in XCTest.
//

import XCTest

final class UIFunctionMatrixUITests: WCS_BIMUITestCase {

  @MainActor
  func testRegistryCatalogIsComplete() {
    XCTAssertGreaterThanOrEqual(UIFunctionRegistry.all.count, 50)
    for area in UIFunctionRegistry.Area.allCases {
      XCTAssertFalse(UIFunctionRegistry.ids(in: area).isEmpty, "No IDs for \(area.rawValue)")
    }
  }

  @MainActor
  func testMatrixAllTabFunctions() throws {
    let app = launchApp()
    for tab in ["Projects", "Site", "AR", "AI", "Export", "Settings"] {
      XCTAssertTrue(tabIsAvailable(tab, in: app), "Missing tab: \(tab)")
      selectTab(tab, in: app)
    }
  }

  @MainActor
  func testMatrixProjectsWorkflow() throws {
    let app = launchApp()
    _ = waitForElement("projects.screen", in: app)
    _ = waitForElement("project.nameField", in: app)
    _ = waitForElement("project.addButton", in: app)

    let name = createProject(named: "Matrix", in: app)
    openProject(named: name, in: app)
    _ = waitForElement("project.openWorkspace", in: app)
    app.buttons["project.editParameters"].tap()
    _ = waitForElement("Inspector_Sheet", in: app)
    if app.buttons["Inspector_Cancel"].exists {
      app.buttons["Inspector_Cancel"].tap()
    }
  }

  @MainActor
  func testMatrixSiteARAIExport() throws {
    let app = launchApp()
    let name = createProject(named: "Matrix Flow", in: app)

    selectTab("Site", in: app)
    _ = waitForElement("site.capture.screen", in: app)
    openFullSiteCapture(in: app)

    selectTab("AR", in: app)
    XCTAssertTrue(
      app.navigationBars["AR Site"].waitForExistence(timeout: 8)
        || app.otherElements["ar.emptyState"].waitForExistence(timeout: 3)
    )

    selectTab("AI", in: app)
    let prompt = aiPromptField(in: app)
    prompt.tap()
    prompt.typeText("UI matrix test")
    dismissKeyboard(in: app)
    app.buttons["ai.generateButton"].tap()
    _ = app.staticTexts.containing(
      NSPredicate(format: "label CONTAINS[c] 'massing' OR label CONTAINS[c] 'offline' OR label CONTAINS[c] 'AI'")
    ).firstMatch.waitForExistence(timeout: 20)

    selectTab("Export", in: app)
    for _ in 0..<4 where !app.buttons["export.ifc"].exists {
      app.swipeUp()
    }
    XCTAssertTrue(app.buttons["export.ifc"].exists)
    XCTAssertTrue(app.buttons["export.cobie"].exists)

    _ = name // keep project in store for export context
  }

  @MainActor
  func testMatrixSettingsAndFeaturePanels() throws {
    let app = launchApp()
    createProject(named: "Settings Matrix", in: app)

    openSettings(in: app)
    _ = waitForElement("settings.installPrograms", in: app)

    openSettingsLink("My subscription", in: app)
    _ = waitForElement("subscription.screen", in: app)

    openSettings(in: app)
    unlockAdminPanel(in: app)

    openSettings(in: app)
    openSettingsLink("Field Systems (sensors & capture)", in: app)
    _ = waitForElement("fieldSystems.screen", in: app)
    app.buttons["fieldSystems.toggleSensors"].tap()

    openSettings(in: app)
    openSettingsLink("Luxe dashboard (chocolate)", in: app)
    _ = waitForElement("luxe.home.screen", in: app)
  }

  @MainActor
  func testMatrixCaptureScreenshotReport() throws {
    let app = launchApp()
    selectTab("Projects", in: app)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "UI Function Matrix — Projects"
    attachment.lifetime = .keepAlways
    add(attachment)

    selectTab("AI", in: app)
    let aiShot = XCTAttachment(screenshot: app.screenshot())
    aiShot.name = "UI Function Matrix — AI"
    aiShot.lifetime = .keepAlways
    add(aiShot)
  }
}
