//
//  WCS_BIMApp.swift
//  ArchFusion BIM (matches ArchFusionBIMApp starter layout)
//

import SwiftUI
import SwiftData

@main
struct WCS_BIMApp: App {
    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
        }
    }
}

/// Loads SwiftData after launch so XCTest can attach before container setup runs.
private struct AppBootstrapView: View {
    @State private var container: ModelContainer?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let container {
                AppShellView()
                    .modelContainer(container)
            } else if let loadError {
                ContentUnavailableView(
                    "Data Store Unavailable",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(loadError)
                )
            } else {
                ProgressView("Loading…")
            }
        }
        .task {
            guard container == nil, loadError == nil else { return }
            do {
                container = try ArchFusionSchema.makeContainerThrowing()
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

/// Canonical app type name from the ArchFusion BIM source pack.
typealias ArchFusionBIMApp = WCS_BIMApp
