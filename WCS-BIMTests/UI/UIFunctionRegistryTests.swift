//
//  UIFunctionRegistryTests.swift
//  WCS-BIMTests
//

import XCTest

final class UIFunctionRegistryTests: XCTestCase {

  func testRegistryMatchesSourceIdentifiers() throws {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("WCS-BIM")

    let swiftFiles = try FileManager.default.subpathsOfDirectory(atPath: root.path)
      .filter { $0.hasSuffix(".swift") }
    let source = swiftFiles
      .map { try? String(contentsOfFile: root.appendingPathComponent($0).path) }
      .compactMap { $0 }
      .joined()

    let missing = UIFunctionRegistry.all
      .map(\.id)
      .filter { !source.contains($0) }

    XCTAssertTrue(
      missing.isEmpty,
      "Registry IDs missing from app source: \(missing.joined(separator: ", "))"
    )
  }

  func testRegistryAreaCoverage() {
    XCTAssertEqual(UIFunctionRegistry.ids(in: .tabs).count, 5)
    XCTAssertEqual(UIFunctionRegistry.ids(in: .more).count, 3)
    XCTAssertEqual(UIFunctionRegistry.ids(in: .export).count, 5)
    XCTAssertFalse(UIFunctionRegistry.ids(in: .fieldSystems).isEmpty)
  }
}

// Mirror registry for unit tests (compile-time duplicate of UITest registry).
enum UIFunctionRegistry {
  enum Area: String, CaseIterable {
    case bootstrap, tabs, more, projects, site, ar, ai, export, settings
    case subscriptions, admin, fieldSystems, appearance, designSystem
  }

  struct Entry {
    let id: String
    let area: Area
    let description: String
  }

  static let all: [Entry] = [
    Entry(id: "bootstrap.loading", area: .bootstrap, description: "loading"),
    Entry(id: "bootstrap.dataStoreError", area: .bootstrap, description: "error"),
    Entry(id: "tab.projects", area: .tabs, description: "Projects tab"),
    Entry(id: "tab.site", area: .tabs, description: "Site tab"),
    Entry(id: "tab.ar", area: .tabs, description: "AR tab"),
    Entry(id: "tab.export", area: .tabs, description: "Export tab"),
    Entry(id: "tab.more", area: .tabs, description: "More tab"),
    Entry(id: "more.screen", area: .more, description: "more"),
    Entry(id: "more.ai", area: .more, description: "AI link"),
    Entry(id: "more.settings", area: .more, description: "Settings link"),
    Entry(id: "projects.screen", area: .projects, description: "list"),
    Entry(id: "projects.heroCard", area: .projects, description: "hero"),
    Entry(id: "project.nameField", area: .projects, description: "name"),
    Entry(id: "project.addButton", area: .projects, description: "add"),
    Entry(id: "project.addCloudButton", area: .projects, description: "cloud"),
    Entry(id: "project.openWorkspace", area: .projects, description: "workspace"),
    Entry(id: "project.editParameters", area: .projects, description: "inspector"),
    Entry(id: "site.capture.screen", area: .site, description: "map"),
    Entry(id: "site.capture.fullLink", area: .site, description: "full link"),
    Entry(id: "site.capture.form", area: .site, description: "form"),
    Entry(id: "site.capture.camera", area: .site, description: "camera"),
    Entry(id: "site.capture.photosPicker", area: .site, description: "photos"),
    Entry(id: "ar.emptyState", area: .ar, description: "empty"),
    Entry(id: "ai.promptField", area: .ai, description: "prompt"),
    Entry(id: "ai.generateButton", area: .ai, description: "generate"),
    Entry(id: "export.screen", area: .export, description: "screen"),
    Entry(id: "export.ifc", area: .export, description: "ifc"),
    Entry(id: "export.cobie", area: .export, description: "cobie"),
    Entry(id: "export.pdf", area: .export, description: "pdf"),
    Entry(id: "export.dwg", area: .export, description: "dwg"),
    Entry(id: "settings.screen", area: .settings, description: "settings"),
    Entry(id: "settings.installPrograms", area: .settings, description: "install"),
    Entry(id: "settings.installMessage", area: .settings, description: "message"),
    Entry(id: "settings.subscription", area: .settings, description: "sub link"),
    Entry(id: "settings.adminAccess", area: .admin, description: "admin link"),
    Entry(id: "settings.fieldSystems", area: .fieldSystems, description: "field link"),
    Entry(id: "settings.luxeDashboard", area: .appearance, description: "luxe"),
    Entry(id: "settings.navigationShowcase", area: .appearance, description: "nav"),
    Entry(id: "settings.learningShell", area: .appearance, description: "learn"),
    Entry(id: "subscription.screen", area: .subscriptions, description: "sub"),
    Entry(id: "subscription.emailField", area: .subscriptions, description: "email"),
    Entry(id: "subscription.applyEmail", area: .subscriptions, description: "apply"),
    Entry(id: "subscription.loadProducts", area: .subscriptions, description: "load"),
    Entry(id: "subscription.restore", area: .subscriptions, description: "restore"),
    Entry(id: "admin.screen", area: .admin, description: "admin"),
    Entry(id: "admin.pinField", area: .admin, description: "pin"),
    Entry(id: "admin.unlock", area: .admin, description: "unlock"),
    Entry(id: "admin.applyOverride", area: .admin, description: "override"),
    Entry(id: "fieldSystems.screen", area: .fieldSystems, description: "field"),
    Entry(id: "fieldSystems.toggleSensors", area: .fieldSystems, description: "sensors"),
    Entry(id: "fieldSystems.openCamera", area: .fieldSystems, description: "camera"),
    Entry(id: "fieldSystems.aiGenerate", area: .fieldSystems, description: "ai"),
    Entry(id: "luxe.home.screen", area: .appearance, description: "luxe screen"),
    Entry(id: "nav.showcase.screen", area: .appearance, description: "nav screen"),
    Entry(id: "learning.shell", area: .appearance, description: "learning"),
    Entry(id: "Inspector_Sheet", area: .designSystem, description: "sheet"),
    Entry(id: "Inspector_Cancel", area: .designSystem, description: "cancel"),
    Entry(id: "Inspector_Save", area: .designSystem, description: "save")
  ]

  static func ids(in area: Area) -> [String] {
    all.filter { $0.area == area }.map(\.id)
  }
}
