import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    private(set) var products: [Product] = []
    private(set) var purchaseMessage = ""
    private(set) var isLoading = false

    let access: SubscriptionAccessController

    init(access: SubscriptionAccessController) {
        self.access = access
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: SubscriptionProductIDs.all)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseMessage = "Could not load products: \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseMessage = "Subscribed to \(product.displayName)."
                await refreshEntitlements()
            case .userCancelled:
                purchaseMessage = "Purchase cancelled."
            case .pending:
                purchaseMessage = "Purchase pending approval."
            @unknown default:
                purchaseMessage = "Unknown purchase result."
            }
        } catch {
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseMessage = "Purchases restored."
        } catch {
            purchaseMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var highest: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  let tier = SubscriptionTier.from(productID: transaction.productID) else { continue }
            highest = max(highest, tier)
        }
        access.applyStoreKitTier(highest)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
