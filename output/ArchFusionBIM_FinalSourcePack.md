# ArchFusion BIM Final Source Pack

Use these as the canonical files. Delete older duplicates.

## 1. ArchFusionBIMApp.swift
```swift
import SwiftUI
import SwiftData

@main
struct ArchFusionBIMApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self, Landmark.self, BIMElement.self, Issue.self,
            DesignOption.self, AssetRecord.self, ExportPackage.self, AIInteraction.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("ModelContainer init failed: \(error)") }
    }()

    var body: some Scene {
        WindowGroup { AppShellView() }
        .modelContainer(sharedModelContainer)
    }
}
```

## 2. Models.swift
```swift
import Foundation
import SwiftData

@Model final class Project { ... }
@Model final class Landmark { ... }
@Model final class BIMElement { ... }
@Model final class Issue { ... }
@Model final class DesignOption { ... }
@Model final class AssetRecord { ... }
@Model final class ExportPackage { ... }
@Model final class AIInteraction { ... }
```

## 3. AppShellView.swift
```swift
import SwiftUI

struct AppShellView: View {
    var body: some View {
        TabView {
            ProjectListView().tabItem { Label("Projects", systemImage: "building.2") }
            SiteCaptureView().tabItem { Label("Site", systemImage: "map") }
            InteractiveARContainer().tabItem { Label("AR", systemImage: "viewfinder") }
            AIAssistantContainer().tabItem { Label("AI", systemImage: "sparkles") }
            ExportCenterView().tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            NavigationStack { SettingsView() }.tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
```

## 4. Services
- `OpenAIClient` and `AIAssistantService` for prompts and responses.
- `CloudKitStore` for project sync.
- `COBieExporter`, `IFCExporter`, and `BIMExportPipeline` for exports.
- `ReportBuilder` for summaries and PDF generation.

## 5. Views
- `ProjectListView`, `ProjectDetailView`, `SiteCaptureView`, `ARInteraction.swift`, `AIAssistantView`, `ExportCenterView`, `SettingsView`, `IntegrationLayer.swift`.

## 6. Minimum logic to keep
- Use `AppShellView` only.
- Use one canonical model file.
- Use one OpenAI service path.
- Use one export pipeline.
- Keep AR tap placement and map/location capture.

## 7. Build order
1. Models.
2. App entry.
3. App shell.
4. Views.
5. Network and CloudKit.
6. Export and reports.
7. Permissions and entitlements.
