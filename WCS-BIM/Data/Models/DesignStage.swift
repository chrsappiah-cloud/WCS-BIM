import Foundation

/// Lifecycle stage for BIM data — design intent, construction, and record/FM stay distinct.
enum DesignStage: String, Codable, CaseIterable, Identifiable {
    case concept
    case technical
    case construction
    case record

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concept: "Concept"
        case .technical: "Technical"
        case .construction: "Construction"
        case .record: "Record / FM"
        }
    }
}

enum ProjectType: String, Codable, CaseIterable, Identifiable {
    case residential
    case commercial
    case airport
    case mixedUse
    case institutional

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .residential: "Residential"
        case .commercial: "Commercial"
        case .airport: "Airport"
        case .mixedUse: "Mixed Use"
        case .institutional: "Institutional"
        }
    }
}
