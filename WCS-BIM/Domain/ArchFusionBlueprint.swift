import Foundation

/// Implementation phases from the ArchFusion BIM full-stack blueprint.
enum ArchFusionPhase: Int, CaseIterable, Identifiable {
    case mvpWorkspace = 1
    case arCaptureAndLibrary = 2
    case aiAndDesignOptions = 3
    case exportAndReporting = 4
    case syncAndFMHandover = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .mvpWorkspace: "MVP workspace + maps + notes"
        case .arCaptureAndLibrary: "AR capture + landmarks + element library"
        case .aiAndDesignOptions: "AI assistant + design options"
        case .exportAndReporting: "Export and reporting"
        case .syncAndFMHandover: "Sync, roles, and FM handover"
        }
    }

    /// Current shipped baseline — phases 1–4 functional; phase 5 partial (CloudKit + FM views).
    static var currentPhase: ArchFusionPhase { .syncAndFMHandover }
}
