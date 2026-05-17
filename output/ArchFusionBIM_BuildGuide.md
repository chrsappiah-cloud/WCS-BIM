# ArchFusion BIM Build Guide

## Xcode setup
1. Create a new iOS App project named `ArchFusionBIM` (this repo uses **`WCS-BIM`** / display name **ArchFusion BIM**).
2. Use SwiftUI and SwiftData.
3. Enable CloudKit capability.
4. Add frameworks: MapKit, CoreLocation, ARKit, RealityKit, CloudKit, PDFKit.
5. Add Info.plist keys: NSCameraUsageDescription, NSLocationWhenInUseUsageDescription, NSPhotoLibraryUsageDescription, NSMotionUsageDescription.

## File groups
| Guide name | This repo |
|------------|-----------|
| ArchFusionBIMApp.swift | `WCS-BIM/WCS_BIMApp.swift` |
| Models.swift | `WCS-BIM/Data/Models/*.swift` + `ModelSchema.swift` |
| MainTabView.swift | `Presentation/MainTabView.swift` (typealias → `AppShellView`) |
| ProjectListView, ProjectDetailView, SiteCaptureView | `Presentation/` |
| ARInteraction.swift | `Spatial/ARInteraction.swift` |
| AIAssistantView.swift | `Presentation/AIAssistantView.swift` (project workspace) |
| ExportCenterView.swift | `Presentation/ExportCenterView.swift` |
| IntegrationLayer.swift | `Presentation/Integration/IntegrationLayer.swift` (`AppShellView`, Settings, tab AI/AR) |
| OpenAIService.swift | `Exchange/OpenAIService.swift` (prompt templates) |
| AIAssistantService.swift | `Domain/Services/AIAssistantService.swift` |
| OpenAIClient.swift | `Exchange/OpenAIClient.swift` (Responses API + chat fallback) |
| NetworkAndCloud.swift | `Exchange/NetworkAndCloud.swift` |
| ExportServices.swift, BIMExportPipeline.swift | `Exchange/` |
| Reports | `Exchange/ReportBuilder.swift`, `PDFReportService.swift` |

## Replace placeholders
- Change `MainTabView()` in the app entry to `AppShellView()` from IntegrationLayer.swift. **Done** in `WCS_BIMApp.swift`.
- Make sure `InteractiveARView` and `ARPlacementCoordinator` are included with ARInteraction.swift. **Done** in `Spatial/ARInteraction.swift`.
- Replace any placeholder text in `ExportCenterView` with real export buttons. **Done** (IFC, COBie, PDF, DWG via `ProjectDetailViewModel`).
- Replace the placeholder OpenAI parser with response decoding from the Responses API. **Done** in `OpenAIClient.parseResponseText`.

## Minimum compile edits
- Ensure `@Model` types are all in the same target.
- Remove duplicate definitions if you keep both older and newer versions of the same view.
- Keep one source of truth for Project, Landmark, BIMElement, Issue, DesignOption, AssetRecord, ExportPackage, and AIInteraction.
- Use only one app shell: `AppShellView`.

## Runtime flow
1. User creates a project.
2. User records site location and landmarks.
3. User places AR objects and captures context.
4. User requests AI concept options.
5. User exports COBie/IFC/PDF packages.
6. User syncs records to CloudKit.

## Notes
- The IFC writer is currently a placeholder and should be expanded to a proper schema writer.
- OpenAI key should be stored securely for production, ideally in Keychain.
- For team collaboration beyond Apple ecosystem, add a backend API later.
