import SwiftUI

/// Five-tab learning shell using `WCSRouteTab.all` and `WCSTabShell`.
public struct WCSLearningShellView: View {
    @State private var selection = 0

    public init() {}

    public var body: some View {
        WCSTabShell(selection: $selection, tabs: WCSRouteTab.all) { tab, _ in
            NavigationStack {
                learningRoot(for: tab)
            }
        }
        .tint(WCSColor.primary)
        .accessibilityIdentifier("learning.shell")
    }

    @ViewBuilder
    private func learningRoot(for tab: WCSRouteTab) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WCSConnectivityBar(left: "Home", right: tab.title)
                WCSSectionHeader(title: tab.title, actionTitle: "Edit", action: {})
                WCSQuickNavGrid(items: [
                    ("Start", "play.fill", {}),
                    ("Review", "eye.fill", {}),
                    ("Reports", "chart.bar.fill", {}),
                    ("Help", "questionmark.circle.fill", {})
                ])
                WCSNavArrowButton(
                    title: "Open \(tab.title)",
                    systemImage: tab.systemImage,
                    action: {}
                )
            }
            .padding(20)
        }
        .navigationTitle(tab.title)
    }
}

#Preview {
    WCSLearningShellView()
}
