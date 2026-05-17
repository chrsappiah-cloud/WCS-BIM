import SwiftData
import SwiftUI

struct ProjectWorkspaceView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProjectDetailViewModel()
    @State private var selectedTab: ProjectTab = .overview

    enum ProjectTab: String, CaseIterable, Identifiable {
        case overview, site, design, massing, ar, ai, export, fm

        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: "Overview"
            case .site: "Site"
            case .design: "Design"
            case .massing: "Massing"
            case .ar: "AR"
            case .ai: "AI"
            case .export: "Export"
            case .fm: "FM"
            }
        }

        var icon: String {
            switch self {
            case .overview: "info.circle"
            case .site: "map"
            case .design: "cube"
            case .massing: "square.stack.3d.down.right"
            case .ar: "arkit"
            case .ai: "sparkles"
            case .export: "square.and.arrow.up"
            case .fm: "wrench.and.screwdriver"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                ForEach(ProjectTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch selectedTab {
                case .overview:
                    ProjectOverviewSection(project: project)
                case .site:
                    SiteCaptureSection(project: project, viewModel: viewModel)
                case .design:
                    DesignSection(project: project, viewModel: viewModel)
                case .massing:
                    NavigationStack { MassingSection(project: project) }
                case .ar:
                    ARSiteSection(project: project, viewModel: viewModel)
                case .ai:
                    AIAssistantView(project: project)
                case .export:
                    ExportCenterView(project: project)
                case .fm:
                    FMHandoverSection(project: project)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.configureMap(for: project) }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(items: [url])
            }
        }
    }
}

struct ProjectOverviewSection: View {
    @Bindable var project: Project
    @State private var sharingService = CloudKitSharingService()

    var body: some View {
        Form {
            Section("Blueprint phase") {
                LabeledContent("Current") {
                    Text(ArchFusionPhase.currentPhase.title).font(.caption)
                }
            }
            Section("Cloud sync") {
                Text(sharingService.sharingStatusMessage())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Project") {
                TextField("Name", text: $project.name)
                Picker("Type", selection: $project.projectTypeRaw) {
                    ForEach(ProjectType.allCases) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }
                Picker("Lifecycle Stage", selection: $project.designStageRaw) {
                    ForEach(DesignStage.allCases) { stage in
                        Text(stage.displayName).tag(stage.rawValue)
                    }
                }
            }
            Section("Site & Program") {
                TextField("Climate", text: $project.climate)
                TextField("Program summary", text: $project.programSummary, axis: .vertical)
                TextField("Constraints", text: $project.constraintsText, axis: .vertical)
                LabeledContent("Coordinates") {
                    Text(String(format: "%.5f, %.5f", project.siteLatitude, project.siteLongitude))
                        .font(.caption.monospaced())
                }
            }
            Section("Notes") {
                TextField("Notes", text: $project.notes, axis: .vertical)
            }
            Section("Summary") {
                LabeledContent("Landmarks", value: "\(project.landmarks.count)")
                LabeledContent("Elements", value: "\(project.elements.count)")
                LabeledContent("Issues", value: "\(project.issues.count)")
                LabeledContent("Assets", value: "\(project.assets.count)")
                LabeledContent("AI interactions", value: "\(project.aiInteractions.count)")
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
