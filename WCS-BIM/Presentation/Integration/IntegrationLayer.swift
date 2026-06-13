import SwiftData
import SwiftUI

struct SettingsView: View {
    var subscriptionManager: SubscriptionManager
    var fieldSystemsHub: APIIntegrationHub

    @AppStorage("openAIApiKey") private var openAIApiKey = ""
    @AppStorage("huggingFaceApiKey") private var huggingFaceApiKey = ""
    @AppStorage("preferredAIProvider") private var preferredAIProvider = "openai.chat"
    @AppStorage("cloudKitEnabled") private var cloudKitEnabled = true
    @AppStorage("designStyle") private var designStyle = "Contemporary"
    @AppStorage("defaultProgram") private var defaultProgram = "Commercial building"
    @AppStorage("bimAPIBaseURL") private var bimAPIBaseURL = "http://127.0.0.1:3000"
    @AppStorage("bimAPIBearerToken") private var bimAPIBearerToken = ""
    @Environment(\.modelContext) private var modelContext
    @State private var installMessage: String?

    var body: some View {
        Form {
            Section("Subscription & TestFlight") {
                NavigationLink("My subscription") {
                    UserSubscriptionPanelView(manager: subscriptionManager)
                }
                .accessibilityIdentifier("settings.subscription")

                NavigationLink("Admin access") {
                    AdminAccessPanelView(access: subscriptionManager.access)
                }
                .accessibilityIdentifier("settings.adminAccess")

                HStack {
                    Text("Current plan")
                    Spacer()
                    StatusChip(
                        text: subscriptionManager.access.activeTier.displayName,
                        tone: .inProgress
                    )
                }
            }
            Section("Appearance") {
                NavigationLink("Luxe dashboard (chocolate)") {
                    WCSLuxeHomeView()
                }
                .accessibilityIdentifier("settings.luxeDashboard")
                NavigationLink("Navigation components") {
                    WCSNavigationShowcaseView()
                }
                .accessibilityIdentifier("settings.navigationShowcase")
                NavigationLink("Learning tab shell (5 tabs)") {
                    WCSLearningShellView()
                }
                .accessibilityIdentifier("settings.learningShell")
            }
            Section("Design pack") {
                Button("Install all design programs") {
                    let projects = DesignProgramInstaller.installAllPrograms(context: modelContext)
                    installMessage = "Installed \(projects.count) program(s) with parametric library elements."
                }
                .accessibilityIdentifier("settings.installPrograms")

                if let installMessage {
                    Text(installMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.installMessage")
                }

                ForEach(DesignProgramCatalog.allPrograms) { program in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(program.name).font(.subheadline)
                        Text(program.programSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("AI & APIs") {
                SecureField("OpenAI API Key", text: $openAIApiKey)
                SecureField("Hugging Face API Key", text: $huggingFaceApiKey)
                TextField("BIM API base URL", text: $bimAPIBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("BIM API bearer token", text: $bimAPIBearerToken)
                Picker("Preferred AI provider", selection: $preferredAIProvider) {
                    Text("OpenAI").tag("openai.chat")
                    Text("Hugging Face").tag("huggingface.inference")
                    Text("Offline").tag("offline.templates")
                }
                NavigationLink("Field Systems (sensors & capture)") {
                    FieldSystemsView(hub: fieldSystemsHub, project: nil)
                }
                .accessibilityIdentifier("settings.fieldSystems")
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
            Section("CloudKit") {
                Text(CloudKitSharingService().sharingStatusMessage())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Guidance") {
                Text("Use the app for concept options, site capture, coordination notes, export, and FM handover.")
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.screen")
    }
}

struct AppShellView: View {
    @State private var workspace = WorkspaceState()
    @State private var subscriptionAccess: SubscriptionAccessController
    @State private var subscriptionManager: SubscriptionManager
    @State private var fieldSystemsHub: APIIntegrationHub
    @State private var selectedTab = 0

    init() {
        let access = SubscriptionAccessController()
        _subscriptionAccess = State(wrappedValue: access)
        _subscriptionManager = State(wrappedValue: SubscriptionManager(access: access))
        _fieldSystemsHub = State(wrappedValue: APIIntegrationHub())
    }

    var body: some View {
        WCSTabShell(selection: $selectedTab, tabs: WCSRouteTab.bimWorkflow) { tab, _ in
            tabRoot(for: tab)
        }
        .tint(WCSColor.primary)
    }

    @ViewBuilder
    private func tabRoot(for tab: WCSRouteTab) -> some View {
        switch tab.id {
        case "projects":
            NavigationStack { ProjectListView(workspace: workspace) }
        case "site":
            NavigationStack { SiteCaptureView() }
        case "ar":
            NavigationStack { ARTabView() }
        case "export":
            NavigationStack { ExportCenterView() }
        case "more":
            NavigationStack {
                MoreToolsView(
                    subscriptionManager: subscriptionManager,
                    fieldSystemsHub: fieldSystemsHub
                )
            }
        default:
            EmptyView()
        }
    }
}

struct MoreToolsView: View {
    var subscriptionManager: SubscriptionManager
    var fieldSystemsHub: APIIntegrationHub

    var body: some View {
        List {
            NavigationLink {
                AIAssistantView()
            } label: {
                Label("AI", systemImage: "sparkles")
            }
            .accessibilityIdentifier("more.ai")

            NavigationLink {
                SettingsView(
                    subscriptionManager: subscriptionManager,
                    fieldSystemsHub: fieldSystemsHub
                )
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityIdentifier("more.settings")
        }
        .navigationTitle("More")
        .accessibilityIdentifier("more.screen")
    }
}

/// Project-aware AR tab wired to SwiftData (replaces standalone AR coordinator).
struct ARTabView: View {
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var selectedProjectID: UUID?
    @State private var viewModel = ProjectDetailViewModel()

    private var selectedProject: Project? {
        guard let selectedProjectID else { return projects.first }
        return projects.first { $0.id == selectedProjectID } ?? projects.first
    }

    var body: some View {
        Group {
            if let project = selectedProject {
                ARSiteSection(project: project, viewModel: viewModel)
            } else {
                ContentUnavailableView(
                    "No Project",
                    systemImage: "building.2",
                    description: Text("Create a project in the Projects tab to use AR site capture.")
                )
                .accessibilityIdentifier("ar.emptyState")
            }
        }
        .navigationTitle("AR Site")
        .toolbar {
            if projects.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Project", selection: $selectedProjectID) {
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(Optional(project.id))
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedProjectID = projects.first?.id
        }
    }
}
