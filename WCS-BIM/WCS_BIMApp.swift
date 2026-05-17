//
//  WCS_BIMApp.swift
//  ArchFusion BIM (matches ArchFusionBIMApp starter layout)
//

import SwiftUI
import SwiftData

@main
struct WCS_BIMApp: App {
    init() {
        if UITestConfiguration.isEnabled {
            ArchFusionSchema.bootstrapForUITesting()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
        }
    }
}

private struct AppBootstrapView: View {
    @State private var container: ModelContainer? = ArchFusionSchema.preloadedContainer
    @State private var loadError: String?

    var body: some View {
        Group {
            if let container {
                AppShellView()
                    .modelContainer(container)
                    .wcsTheme()
            } else if let loadError {
                ContentUnavailableView(
                    "Data Store Unavailable",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(loadError)
                )
                .accessibilityIdentifier("bootstrap.dataStoreError")
            } else {
                ProgressView("Loading…")
                    .accessibilityIdentifier("bootstrap.loading")
            }
        }
        .task { await loadContainerIfNeeded() }
    }

    @MainActor
    private func loadContainerIfNeeded() async {
        guard container == nil, loadError == nil else { return }

        if let shared = ArchFusionSchema.preloadedContainer ?? ArchFusionSchema.sharedTestContainer {
            container = shared
            return
        }

        if UITestConfiguration.isEnabled {
            if let uiTest = ArchFusionSchema.makeUITestContainer() {
                container = uiTest
                ArchFusionSchema.registerPreloadedContainer(uiTest)
            } else {
                loadError = ModelContainerBootstrapError.unavailable("uitest").localizedDescription
            }
            return
        }

        do {
            let cloudKit = ArchFusionSchema.isRunningUnderXCTest ? false : nil
            let loaded = try ArchFusionSchema.makeContainerThrowing(cloudKitEnabled: cloudKit)
            container = loaded
            ArchFusionSchema.registerPreloadedContainer(loaded)
        } catch {
            if let fallback = ArchFusionSchema.makeUITestContainer() {
                container = fallback
                ArchFusionSchema.registerPreloadedContainer(fallback)
            } else {
                loadError = error.localizedDescription
            }
        }
    }
}

typealias ArchFusionBIMApp = WCS_BIMApp
