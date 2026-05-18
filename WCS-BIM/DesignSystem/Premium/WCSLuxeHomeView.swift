import SwiftUI

/// Chocolate luxe dashboard showcase for ArchFusion BIM workflows.
public struct WCSLuxeHomeView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsRow
                PremiumCard(title: "Today", subtitle: "Projects and coordination summary") {
                    VStack(alignment: .leading, spacing: 10) {
                        progressRow(label: "Models synced", value: "8/12", fraction: 0.67)
                        progressRow(label: "Open issues", value: "5", fraction: 0.45)
                    }
                }
                PremiumCard(title: "Quick Actions", subtitle: "Launch common WCS-BIM workflows") {
                    VStack(spacing: 12) {
                        Button("New project") {}
                            .buttonStyle(DiamondButtonStyle())
                            .accessibilityIdentifier("luxe.action.newProject")
                        Button("Site capture") {}
                            .buttonStyle(DiamondButtonStyle())
                            .accessibilityIdentifier("luxe.action.siteCapture")
                        Button("AI assistant") {}
                            .buttonStyle(DiamondButtonStyle())
                            .accessibilityIdentifier("luxe.action.ai")
                    }
                }
                PremiumCard(title: "Highlights", subtitle: "Sparkling insights and updates") {
                    VStack(alignment: .leading, spacing: 8) {
                        labelChip("New")
                        Text(
                            "Chocolate-toned luxe UI with diamond accents — premium feel for field BIM coordination."
                        )
                        .font(.callout)
                        .foregroundStyle(WCSLuxePalette.diamond.opacity(0.9))
                    }
                }
            }
            .padding(20)
        }
        .wcsLuxeChrome()
        .accessibilityIdentifier("luxe.home.screen")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("WCS-BIM")
                    .font(.largeTitle.bold())
                    .foregroundStyle(WCSLuxePalette.diamond)
                Text("Chocolate luxe workspace")
                    .foregroundStyle(WCSLuxePalette.champagne.opacity(0.85))
            }
            Spacer()
            Circle()
                .fill(
                    LinearGradient(
                        colors: [WCSLuxePalette.diamond, WCSLuxePalette.champagne],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(WCSLuxePalette.espresso)
                )
                .diamondGlow()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "12", subtitle: "Projects")
            statCard(title: "5", subtitle: "Issues")
            statCard(title: "98%", subtitle: "Sync")
        }
    }

    private func statCard(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.title3.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(WCSLuxePalette.champagne.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(WCSLuxePalette.diamond.opacity(0.18), lineWidth: 1)
        )
        .foregroundStyle(WCSLuxePalette.diamond)
    }

    private func progressRow(label: String, value: String, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text(value).foregroundStyle(WCSLuxePalette.champagne)
            }
            ProgressView(value: fraction)
                .tint(WCSLuxePalette.gold)
        }
    }

    private func labelChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(WCSLuxePalette.gold.opacity(0.2))
            .foregroundStyle(WCSLuxePalette.diamond)
            .clipShape(Capsule())
    }
}

#Preview {
    WCSLuxeHomeView()
}
