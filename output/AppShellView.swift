import SwiftUI

struct AppShellView: View {
    var body: some View {
        TabView {
            NavigationStack { ProjectListView() }
                .tabItem { Label("Projects", systemImage: "building.2") }
            NavigationStack { SiteCaptureView() }
                .tabItem { Label("Site", systemImage: "map") }
            NavigationStack { InteractiveARContainer() }
                .tabItem { Label("AR", systemImage: "viewfinder") }
            NavigationStack { AIAssistantContainer() }
                .tabItem { Label("AI", systemImage: "sparkles") }
            NavigationStack { ExportCenterView() }
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
