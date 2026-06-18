import StoreKit
import SwiftUI

struct UserSubscriptionPanelView: View {
    @Bindable var manager: SubscriptionManager
    @State private var email = ""

    var body: some View {
        List {
            Section {
                HStack {
                    StatusChip(text: manager.access.activeTier.displayName, tone: .inProgress)
                    Spacer()
                    if manager.isLoading {
                        ProgressView()
                    }
                }
                Text("Active plan controls export, AI, and CloudKit features.")
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.75))
            }

            Section("Account email (TestFlight registry)") {
                TextField("you@company.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .accessibilityIdentifier("subscription.emailField")
                    .onAppear { email = manager.access.userEmail }
                PrimaryButton("Apply email", layout: .compact) {
                    manager.access.setUserEmail(email)
                }
                .accessibilityIdentifier("subscription.applyEmail")
            }

            Section("Plans") {
                if manager.products.isEmpty && manager.isLoading && !manager.didAttemptProductLoad {
                    HStack {
                        ProgressView()
                        Text("Loading App Store products…")
                            .font(WCSFont.caption())
                    }
                }

                if manager.products.isEmpty {
                    ForEach(SubscriptionPlanCatalog.reviewSafePlans) { plan in
                        fallbackPlanRow(plan)
                    }

                    PrimaryButton("Load plans") {
                        Task { await manager.loadProducts() }
                    }
                    .accessibilityIdentifier("subscription.loadProducts")
                } else {
                    ForEach(manager.products, id: \.id) { product in
                        VStack(alignment: .leading, spacing: WCSSpacing.xs) {
                            Text(product.displayName)
                                .font(WCSFont.title(16))
                            Text(product.description)
                                .font(WCSFont.caption())
                                .foregroundStyle(WCSColor.neutralText.opacity(0.7))
                            PrimaryButton("Subscribe \(product.displayPrice)", layout: .compact) {
                                Task { await manager.purchase(product) }
                            }
                            .accessibilityIdentifier("subscription.buy.\(product.id)")
                        }
                        .padding(.vertical, WCSSpacing.xxs)
                    }
                }
            }

            Section {
                SecondaryButton("Restore purchases") {
                    Task { await manager.restore() }
                }
                .accessibilityIdentifier("subscription.restore")
            }

            if !manager.purchaseMessage.isEmpty {
                Section {
                    Text(manager.purchaseMessage)
                        .font(WCSFont.caption())
                        .accessibilityIdentifier("subscription.message")
                }
            }
        }
        .navigationTitle("Subscription")
        .accessibilityIdentifier("subscription.screen")
        .task { await manager.loadProducts() }
    }

    private func fallbackPlanRow(_ plan: SubscriptionPlanSummary) -> some View {
        VStack(alignment: .leading, spacing: WCSSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.displayName)
                    .font(WCSFont.title(16))
                Spacer()
                StatusChip(text: plan.fallbackPrice, tone: .inProgress)
            }
            Text(plan.description)
                .font(WCSFont.caption())
                .foregroundStyle(WCSColor.neutralText.opacity(0.72))
            VStack(alignment: .leading, spacing: WCSSpacing.xxs) {
                ForEach(plan.includedFeatures, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.seal.fill")
                        .font(WCSFont.caption())
                        .foregroundStyle(WCSColor.neutralText.opacity(0.78))
                }
            }
            Text("Purchasing becomes available when App Store products finish loading.")
                .font(WCSFont.caption())
                .foregroundStyle(WCSColor.neutralText.opacity(0.62))
        }
        .padding(.vertical, WCSSpacing.xxs)
        .accessibilityIdentifier("subscription.plan.\(plan.id)")
    }
}
