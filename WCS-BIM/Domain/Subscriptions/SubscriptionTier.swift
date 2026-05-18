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
