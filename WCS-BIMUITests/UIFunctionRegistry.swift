//
//  UIFunctionRegistry.swift
//  WCS-BIMUITests
//
//  Canonical list of accessibility identifiers exercised by UI tests.
//

import Foundation

enum UIFunctionRegistry {
  enum Area: String, CaseIterable {
    case bootstrap = "Bootstrap"
    case tabs = "Tabs"
    case more = "More"
    case projects = "Projects"
    case site = "Site"
    case ar = "AR"
    case ai = "AI"
    case export = "Export"
    case settings = "Settings"
    case subscriptions = "Subscriptions"
    case admin = "Admin"
    case fieldSystems = "Field Systems"
    case appearance = "Appearance"
    case designSystem = "Design System"
  }

  struct Entry: Identifiable {
    let id: String
    let area: Area
    let description: String
  }

  static let all: [Entry] = [
    // Bootstrap
    Entry(id: "bootstrap.loading", area: .bootstrap, description: "SwiftData loading"),
    Entry(id: "bootstrap.dataStoreError", area: .bootstrap, description: "Store failure"),
    // Tabs
    Entry(id: "tab.projects", area: .tabs, description: "Projects tab"),
    Entry(id: "tab.site", area: .tabs, description: "Site tab"),
    Entry(id: "tab.ar", area: .tabs, description: "AR tab"),
    Entry(id: "tab.export", area: .tabs, description: "Export tab"),
    Entry(id: "tab.more", area: .tabs, description: "More tab"),
    // More
    Entry(id: "more.screen", area: .more, description: "More root"),
    Entry(id: "more.ai", area: .more, description: "AI link"),
    Entry(id: "more.settings", area: .more, description: "Settings link"),
    // Projects
    Entry(id: "projects.screen", area: .projects, description: "Project list"),
    Entry(id: "projects.heroCard", area: .projects, description: "Hero card"),
    Entry(id: "project.nameField", area: .projects, description: "New project name"),
    Entry(id: "project.addButton", area: .projects, description: "Add project"),
    Entry(id: "project.addCloudButton", area: .projects, description: "Add + CloudKit"),
    Entry(id: "project.openWorkspace", area: .projects, description: "Open workspace"),
    Entry(id: "project.editParameters", area: .projects, description: "Inspector entry"),
    // Site
    Entry(id: "site.capture.screen", area: .site, description: "Site map"),
    Entry(id: "site.capture.fullLink", area: .site, description: "Full capture link"),
    Entry(id: "site.capture.form", area: .site, description: "Full capture form"),
    Entry(id: "site.capture.camera", area: .site, description: "Live camera"),
    Entry(id: "site.capture.photosPicker", area: .site, description: "Photo library"),
    // AR
    Entry(id: "ar.emptyState", area: .ar, description: "No project state"),
    // AI
    Entry(id: "ai.promptField", area: .ai, description: "Prompt field"),
    Entry(id: "ai.generateButton", area: .ai, description: "Generate"),
    // Export
    Entry(id: "export.screen", area: .export, description: "Export center"),
    Entry(id: "export.ifc", area: .export, description: "IFC export"),
    Entry(id: "export.cobie", area: .export, description: "COBie export"),
    Entry(id: "export.pdf", area: .export, description: "PDF export"),
    Entry(id: "export.dwg", area: .export, description: "DWG export"),
    // Settings
    Entry(id: "settings.screen", area: .settings, description: "Settings root"),
    Entry(id: "settings.installPrograms", area: .settings, description: "Design pack install"),
    Entry(id: "settings.installMessage", area: .settings, description: "Install feedback"),
    Entry(id: "settings.subscription", area: .settings, description: "Subscription link"),
    Entry(id: "settings.adminAccess", area: .settings, description: "Admin link"),
    Entry(id: "settings.fieldSystems", area: .settings, description: "Field systems link"),
    Entry(id: "settings.luxeDashboard", area: .settings, description: "Luxe dashboard link"),
    Entry(id: "settings.navigationShowcase", area: .settings, description: "Navigation showcase"),
    Entry(id: "settings.learningShell", area: .settings, description: "Learning shell"),
    // Subscriptions
    Entry(id: "subscription.screen", area: .subscriptions, description: "Subscription panel"),
    Entry(id: "subscription.emailField", area: .subscriptions, description: "Email field"),
    Entry(id: "subscription.applyEmail", area: .subscriptions, description: "Apply email"),
    Entry(id: "subscription.loadProducts", area: .subscriptions, description: "Load products"),
    Entry(id: "subscription.restore", area: .subscriptions, description: "Restore purchases"),
    // Admin
    Entry(id: "admin.screen", area: .admin, description: "Admin panel"),
    Entry(id: "admin.pinField", area: .admin, description: "Admin PIN"),
    Entry(id: "admin.unlock", area: .admin, description: "Unlock admin"),
    Entry(id: "admin.applyOverride", area: .admin, description: "Tier override"),
    // Field systems
    Entry(id: "fieldSystems.screen", area: .fieldSystems, description: "Field systems"),
    Entry(id: "fieldSystems.toggleSensors", area: .fieldSystems, description: "Toggle sensors"),
    Entry(id: "fieldSystems.openCamera", area: .fieldSystems, description: "Open camera"),
    Entry(id: "fieldSystems.aiGenerate", area: .fieldSystems, description: "Field AI generate"),
    // Appearance
    Entry(id: "luxe.home.screen", area: .appearance, description: "Luxe dashboard"),
    Entry(id: "nav.showcase.screen", area: .appearance, description: "Navigation showcase"),
    Entry(id: "learning.shell", area: .appearance, description: "Learning tab shell"),
    // Design system
    Entry(id: "Inspector_Sheet", area: .designSystem, description: "Inspector sheet"),
    Entry(id: "Inspector_Cancel", area: .designSystem, description: "Inspector cancel"),
    Entry(id: "Inspector_Save", area: .designSystem, description: "Inspector save")
  ]

  static func ids(in area: Area) -> [String] {
    all.filter { $0.area == area }.map(\.id)
  }
}
