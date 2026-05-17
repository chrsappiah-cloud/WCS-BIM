import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIApiKey") private var openAIApiKey = ""
    @AppStorage("cloudKitEnabled") private var cloudKitEnabled = true
    @AppStorage("designStyle") private var designStyle = "Contemporary"
    @AppStorage("defaultProgram") private var defaultProgram = "Commercial building"

    var body: some View {
        Form {
            Section("AI") {
                SecureField("OpenAI API Key", text: $openAIApiKey)
                Picker("Style", selection: $designStyle) {
                    Text("Contemporary").tag("Contemporary")
                    Text("Minimal").tag("Minimal")
                    Text("Parametric").tag("Parametric")
                    Text("Airport").tag("Airport")
                    Text("Commercial").tag("Commercial")
                }
            }
            Section("Defaults") {
                TextField("Program", text: $defaultProgram)
                Toggle("Enable CloudKit", isOn: $cloudKitEnabled)
            }
            Section("Guidance") {
                Text("Use the app for concept options, site capture, coordination notes, export, and FM handover.")
            }
        }
        .navigationTitle("Settings")
    }
}

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

struct AIAssistantContainer: View {
    @AppStorage("openAIApiKey") private var apiKey = ""
    @AppStorage("defaultProgram") private var defaultProgram = "Commercial building"
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            TextField("Ask for massing, zoning, circulation, sustainability...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button(isLoading ? "Generating..." : "Generate") {
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    do {
                        let service = AIAssistantService(apiKey: apiKey)
                        response = try await service.generateConcepts(
                            projectName: "New Project",
                            site: "Geo-located site",
                            landmarks: ["Waterfront", "Transit hub"],
                            program: prompt.isEmpty ? defaultProgram : prompt
                        )
                    } catch {
                        response = "AI error: \(error.localizedDescription)"
                    }
                }
            }
            ScrollView { Text(response).frame(maxWidth: .infinity, alignment: .leading) }
            Spacer()
        }
        .padding()
        .navigationTitle("AI Assistant")
    }
}

struct InteractiveARContainer: View {
    @StateObject private var coordinator = ARPlacementCoordinator()

    var body: some View {
        ZStack(alignment: .topLeading) {
            InteractiveARView(coordinator: coordinator)
                .ignoresSafeArea()
            Text(coordinator.statusText)
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
    }
}
