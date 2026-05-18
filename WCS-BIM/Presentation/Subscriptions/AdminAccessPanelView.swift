import SwiftUI

struct AdminAccessPanelView: View {
    @Bindable var access: SubscriptionAccessController
    @State private var pin = ""
    @State private var authError = ""
    @State private var grantEmail = ""
    @State private var grantTier: SubscriptionTier = .pro
    @State private var statusMessage = ""

    var body: some View {
        Group {
            if access.isAdminUnlocked {
                adminForm
            } else {
                unlockForm
            }
        }
        .navigationTitle("Admin Access")
        .accessibilityIdentifier("admin.screen")
    }

    private var unlockForm: some View {
        Form {
            Section("Administrator unlock") {
                SecureField("Admin PIN", text: $pin)
                    .accessibilityIdentifier("admin.pinField")
                PrimaryButton("Unlock") {
                    if access.unlockAdmin(pin: pin) {
                        authError = ""
                        pin = ""
                    } else {
                        authError = "Invalid PIN."
                    }
                }
                .accessibilityIdentifier("admin.unlock")
                if !authError.isEmpty {
                    Text(authError)
                        .font(WCSFont.caption())
                        .foregroundStyle(WCSColor.error)
                }
            }
            Section {
                Text("Controls TestFlight tier overrides and payment access flags. Use scripts/testflight/admin_cli.py for App Store Connect invites.")
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.7))
            }
        }
    }

    private var adminForm: some View {
        Form {
            Section("Override tier (this device)") {
                Picker("Tier", selection: $grantTier) {
                    ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }
                .accessibilityIdentifier("admin.tierPicker")
                PrimaryButton("Apply override") {
                    access.setAdminOverride(grantTier == .free ? nil : grantTier)
                    statusMessage = "Override set to \(grantTier.displayName)."
                }
                .accessibilityIdentifier("admin.applyOverride")
                SecondaryButton("Clear override") {
                    access.setAdminOverride(nil)
                    statusMessage = "Override cleared."
                }
                .accessibilityIdentifier("admin.clearOverride")
            }

            Section("Registry (bundled)") {
                if access.registryEntries.isEmpty {
                    Text("No bundled access entries.")
                        .font(WCSFont.caption())
                } else {
                    ForEach(access.registryEntries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.email).font(WCSFont.label())
                            HStack {
                                StatusChip(text: entry.tier, tone: .neutral)
                                if entry.testflight == true {
                                    StatusChip(text: "TestFlight", tone: .inProgress)
                                }
                            }
                            if let ref = entry.paymentRef, !ref.isEmpty {
                                Text("Payment: \(ref)").font(WCSFont.caption())
                            }
                        }
                    }
                }
            }

            Section("Grant local tester") {
                TextField("Email", text: $grantEmail)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("admin.grantEmail")
                PrimaryButton("Grant Pro (local)") {
                    access.setUserEmail(grantEmail)
                    access.setAdminOverride(.pro)
                    statusMessage = "Granted Pro for \(grantEmail) on this install."
                }
                .accessibilityIdentifier("admin.grantLocal")
            }

            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .font(WCSFont.caption())
                        .accessibilityIdentifier("admin.status")
                }
            }

            Section {
                SecondaryButton("Lock admin") {
                    access.lockAdmin()
                }
                .accessibilityIdentifier("admin.lock")
            }
        }
    }
}
