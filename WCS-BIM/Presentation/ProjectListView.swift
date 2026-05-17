import CoreLocation
import SwiftData
import SwiftUI

struct ProjectListView: View {
    var workspace: WorkspaceState?
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                CardView(
                    title: "ArchFusion BIM",
                    subtitle: "Professional field & model workspace",
                    systemImage: "sparkles",
                    chips: ["BIM", "Field", "Export"],
                    pearl: true
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("projects.heroCard")
            }

            Section("Create") {
                TextField("Project name", text: $newName)
                    .font(WCSFont.body())
                    .accessibilityIdentifier("project.nameField")

                HStack(spacing: WCSSpacing.sm) {
                    PrimaryButton("Add", layout: .compact) {
                        createProject(syncCloud: false)
                    }
                    .accessibilityIdentifier("project.addButton")

                    SecondaryButton("Add + CloudKit") {
                        createProject(syncCloud: true)
                    }
                    .accessibilityIdentifier("project.addCloudButton")
                }
            }

            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        CardView(
                            title: project.name,
                            subtitle: project.projectType.rawValue.capitalized,
                            systemImage: "building.2",
                            chips: [project.designStage.rawValue.capitalized]
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteProjects)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("Projects")
        .accessibilityIdentifier("projects.screen")
        .onAppear {
            locationService.requestPermission()
        }
    }

    private func createProject(syncCloud: Bool = false) {
        var lat = 0.0
        var lon = 0.0
        if let loc = locationService.currentLocation {
            lat = loc.coordinate.latitude
            lon = loc.coordinate.longitude
        }
        let project = Project(
            name: newName.isEmpty ? "Untitled Project" : newName,
            siteLatitude: lat,
            siteLongitude: lon
        )
        modelContext.insert(project)
        workspace?.select(project)
        newName = ""

        if syncCloud {
            Task {
                let store = CloudKitStore()
                try? await store.saveProject(
                    name: project.name,
                    latitude: project.siteLatitude,
                    longitude: project.siteLongitude,
                    notes: project.notes
                )
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(projects[index])
        }
    }
}
