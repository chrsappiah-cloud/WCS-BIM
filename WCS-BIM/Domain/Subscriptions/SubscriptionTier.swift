import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Comparable {
    case free
    case pro
    case team
    case enterprise

    var displayName: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        case .team: "Team"
        case .enterprise: "Enterprise"
        }
    }

    var sortOrder: Int {
        switch self {
        case .free: 0
        case .pro: 1
        case .team: 2
        case .enterprise: 3
        }
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    static func from(productID: String) -> SubscriptionTier? {
        switch productID {
        case SubscriptionProductIDs.proMonthly: .pro
        case SubscriptionProductIDs.teamMonthly: .team
        case SubscriptionProductIDs.enterpriseMonthly: .enterprise
        default: nil
        }
    }
}

enum SubscriptionProductIDs {
    static let proMonthly = "wcs.bim.pro.monthly"
    static let teamMonthly = "wcs.bim.team.monthly"
    static let enterpriseMonthly = "wcs.bim.enterprise.monthly"

    static let all: [String] = [proMonthly, teamMonthly, enterpriseMonthly]
}

struct SubscriptionPlanSummary: Identifiable, Equatable {
    let id: String
    let tier: SubscriptionTier
    let displayName: String
    let fallbackPrice: String
    let description: String
    let includedFeatures: [String]
}

enum SubscriptionPlanCatalog {
    static let reviewSafePlans: [SubscriptionPlanSummary] = [
        SubscriptionPlanSummary(
            id: SubscriptionProductIDs.proMonthly,
            tier: .pro,
            displayName: "Pro",
            fallbackPrice: "Monthly plan",
            description: "For independent BIM professionals who need AI assistance, exports, and field-ready project workflows.",
            includedFeatures: ["AI assistant", "IFC/PDF exports", "AR site capture"]
        ),
        SubscriptionPlanSummary(
            id: SubscriptionProductIDs.teamMonthly,
            tier: .team,
            displayName: "Team",
            fallbackPrice: "Monthly plan",
            description: "For studios coordinating multiple projects, shared reviews, CloudKit workflows, and role-based delivery.",
            includedFeatures: ["Team collaboration", "Cloud-ready project sync", "Issue and asset coordination"]
        ),
        SubscriptionPlanSummary(
            id: SubscriptionProductIDs.enterpriseMonthly,
            tier: .enterprise,
            displayName: "Enterprise",
            fallbackPrice: "Monthly plan",
            description: "For organizations needing governance, advanced integrations, model registry workflows, and deployment controls.",
            includedFeatures: ["Integration layer", "Model registry", "Governance dashboards"]
        )
    ]
}

struct SubscriptionAccessEntry: Codable, Identifiable {
    var id: String { email }
    var email: String
    var tier: String
    var expiresAt: String?
    var paymentRef: String?
    var testflight: Bool?
}

struct SubscriptionAccessRegistry: Codable {
    var version: Int
    var updatedAt: String?
    var entries: [SubscriptionAccessEntry]
}
