import Foundation

/// Merges StoreKit entitlements, admin overrides, and bundled access registry.
@MainActor
@Observable
final class SubscriptionAccessController {
    private(set) var activeTier: SubscriptionTier = .free
    private(set) var adminOverrideTier: SubscriptionTier?
    private(set) var registryEntries: [SubscriptionAccessEntry] = []

    private let defaults = UserDefaults.standard
    private var storeKitTier: SubscriptionTier = .free

    private enum Keys {
        static let adminUnlocked = "subscription.adminUnlocked"
        static let overrideTier = "subscription.overrideTier"
        static let userEmail = "subscription.userEmail"
    }

    init() {
        reloadOverrides()
        loadBundledRegistry()
        recomputeTier()
    }

    func reloadOverrides() {
        let raw = defaults.string(forKey: Keys.overrideTier) ?? ""
        adminOverrideTier = raw.isEmpty ? nil : SubscriptionTier(rawValue: raw)
    }

    func setAdminOverride(_ tier: SubscriptionTier?) {
        adminOverrideTier = tier
        defaults.set(tier?.rawValue ?? "", forKey: Keys.overrideTier)
        recomputeTier()
    }

    func setUserEmail(_ email: String) {
        defaults.set(email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.userEmail)
        recomputeTier()
    }

    var userEmail: String {
        defaults.string(forKey: Keys.userEmail) ?? ""
    }

    func applyStoreKitTier(_ tier: SubscriptionTier) {
        storeKitTier = tier
        recomputeTier()
    }

    private func recomputeTier() {
        let registryTier = tierFromRegistry(email: userEmail)
        let candidates = [storeKitTier, registryTier, adminOverrideTier ?? .free]
        activeTier = candidates.max() ?? .free
    }

    private func tierFromRegistry(email: String) -> SubscriptionTier {
        guard !email.isEmpty else { return .free }
        let entry = registryEntries.first { $0.email.lowercased() == email.lowercased() }
        guard let entry else { return .free }
        if let expires = entry.expiresAt,
           let date = ISO8601DateFormatter().date(from: expires),
           date < Date() {
            return .free
        }
        return SubscriptionTier(rawValue: entry.tier) ?? .free
    }

    private func loadBundledRegistry() {
        guard let url = Bundle.main.url(forResource: "access_registry", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let registry = try? JSONDecoder().decode(SubscriptionAccessRegistry.self, from: data)
        else { return }
        registryEntries = registry.entries
    }

    var isAdminUnlocked: Bool {
        defaults.bool(forKey: Keys.adminUnlocked)
    }

    func unlockAdmin(pin: String) -> Bool {
        let expected = ProcessInfo.processInfo.environment["WCS_ADMIN_PIN"]
            ?? defaults.string(forKey: "wcs.admin.pin")
            ?? "wcs-admin"
        guard pin == expected else { return false }
        defaults.set(true, forKey: Keys.adminUnlocked)
        return true
    }

    func lockAdmin() {
        defaults.set(false, forKey: Keys.adminUnlocked)
    }

    func hasFeature(_ feature: SubscriptionFeature) -> Bool {
        activeTier >= feature.minimumTier
    }
}

enum SubscriptionFeature {
    case exportIFC
    case exportCOBie
    case aiAssistant
    case cloudKitSync
    case unlimitedProjects

    var minimumTier: SubscriptionTier {
        switch self {
        case .unlimitedProjects, .aiAssistant: .pro
        case .exportIFC, .exportCOBie: .pro
        case .cloudKitSync: .team
        }
    }
}
