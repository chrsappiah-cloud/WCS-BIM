import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    typealias ProductLoader = () async throws -> [Product]

    private enum ProductLoadError: LocalizedError {
        case timedOut

        var errorDescription: String? {
            switch self {
            case .timedOut:
                "the App Store did not respond before the review-safe timeout"
            }
        }
    }

    private static let fallbackAvailabilityMessage = "Plans are shown below. App Store purchase options are not available in the current environment, so plan details remain visible for review."

    private(set) var products: [Product] = []
    private(set) var purchaseMessage = ""
    private(set) var isLoading = false
    private(set) var didAttemptProductLoad = false

    let access: SubscriptionAccessController

    private let productLoader: ProductLoader
    private let productLoadTimeoutNanoseconds: UInt64

    init(
        access: SubscriptionAccessController,
        productLoadTimeoutNanoseconds: UInt64 = 8_000_000_000,
        productLoader: @escaping ProductLoader = {
            try await Product.products(for: SubscriptionProductIDs.all)
        }
    ) {
        self.access = access
        self.productLoadTimeoutNanoseconds = productLoadTimeoutNanoseconds
        self.productLoader = productLoader
    }

    func loadProducts() async {
        guard !isLoading else {
            purchaseMessage = "Plans are already refreshing. The available plan summaries remain visible below."
            return
        }

        isLoading = true
        didAttemptProductLoad = true
        purchaseMessage = "Refreshing App Store plans. Plan summaries remain available below."
        defer { isLoading = false }

        do {
            products = try await loadProductsWithTimeout()
                .sorted { $0.price < $1.price }
            purchaseMessage = products.isEmpty ? Self.fallbackAvailabilityMessage : "App Store plans loaded."
        } catch {
            products = []
            purchaseMessage = "\(Self.fallbackAvailabilityMessage) Reason: \(error.localizedDescription)."
        }
        await refreshEntitlements()
    }

    private func loadProductsWithTimeout() async throws -> [Product] {
        try await withThrowingTaskGroup(of: [Product].self) { group in
            group.addTask {
                try await self.productLoader()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: self.productLoadTimeoutNanoseconds)
                throw ProductLoadError.timedOut
            }

            guard let products = try await group.next() else {
                group.cancelAll()
                return []
            }
            group.cancelAll()
            return products
        }
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
