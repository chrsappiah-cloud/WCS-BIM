import SwiftData
import SwiftUI

struct ExportCenterView: View {
    var fixedProject: Project?

    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProjectDetailViewModel()
    @State private var selectedProjectID: UUID?

    init(project: Project? = nil) {
        self.fixedProject = project
    }

    private var activeProject: Project? {
        if let fixedProject { return fixedProject }
        guard let selectedProjectID else { return projects.first }
        return projects.first { $0.id == selectedProjectID } ?? projects.first
    }

    var body: some View {
        List {
            if projects.isEmpty {
                Text("Create a project to export IFC, COBie, and PDF deliverables.")
                    .foregroundStyle(.secondary)
            } else {
                if fixedProject == nil, projects.count > 1 {
                    Section("Project") {
                        Picker("Active", selection: $selectedProjectID) {
                            ForEach(projects, id: \.id) { p in
                                Text(p.name).tag(Optional(p.id))
                            }
                        }
                    }
                }

                if let activeProject {
                    Button("Export IFC") {
                        viewModel.export("IFC", project: activeProject, context: modelContext)
                    }
                    Button("Export COBie CSV") {
                        viewModel.export("COBie", project: activeProject, context: modelContext)
                    }
                    Button("Export PDF sheets") {
                        viewModel.export("PDF", project: activeProject, context: modelContext)
                    }
                    Button("Revit / DWG handoff JSON") {
                        viewModel.export("DWG", project: activeProject, context: modelContext)
                    }
                }
            }

            Section {
                Text(CloudKitSharingService().sharingStatusMessage())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sync to CloudKit")
            }

            if let message = viewModel.exportMessage {
                Section { Text(message).font(.caption) }
            }
        }
        .navigationTitle("Export Center")
        .onAppear {
            if selectedProjectID == nil {
                selectedProjectID = fixedProject?.id ?? projects.first?.id
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(items: [url])
            }
        }
    }
}
