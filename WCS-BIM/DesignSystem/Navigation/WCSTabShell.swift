import SwiftUI

/// Reusable tab shell — one content builder per route (fixes placeholder-only tabs).
public struct WCSTabShell<TabContent: View>: View {
    @Binding var selection: Int
    let tabs: [WCSRouteTab]
    @ViewBuilder let tabContent: (WCSRouteTab, Int) -> TabContent

    public init(
        selection: Binding<Int>,
        tabs: [WCSRouteTab],
        @ViewBuilder tabContent: @escaping (WCSRouteTab, Int) -> TabContent
    ) {
        _selection = selection
        self.tabs = tabs
        self.tabContent = tabContent
    }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs.indices, id: \.self) { index in
                let tab = tabs[index]
                tabContent(tab, index)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(index)
                    .accessibilityIdentifier(tab.accessibilityIdentifier ?? "tab.\(tab.id)")
            }
        }
    }
}

public extension WCSTabShell {
    /// Design-kit style: single root `content` on the first tab; other tabs show placeholders
    /// until you supply a per-tab builder via `init(selection:tabs:tabContent:)`.
    init(
        selection: Binding<Int>,
        tabs: [WCSRouteTab] = WCSRouteTab.all,
        @ViewBuilder content: @escaping () -> TabContent
    ) where TabContent == AnyView {
        self.init(selection: selection, tabs: tabs) { tab, index in
            AnyView(
                Group {
                    if index == 0 {
                        content()
                    } else {
                        ContentUnavailableView(
                            tab.title,
                            systemImage: tab.systemImage,
                            description: Text("Connect this tab in `tabContent`.")
                        )
                    }
                }
            )
        }
    }
}
