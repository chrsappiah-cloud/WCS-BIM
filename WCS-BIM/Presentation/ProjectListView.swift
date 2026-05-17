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
            Section("Create") {
                HStack {
                    TextField("Project name", text: $newName)
                    Button("Add") {
                        createProject(syncCloud: false)
                    }
                    Button("Add + CloudKit", systemImage: "icloud") {
                        createProject(syncCloud: true)
                    }
                }
            }
            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink(project.name) {
                        ProjectDetailView(project: project)
                    }
                }
                .onDelete(perform: deleteProjects)
            }
        }
        .navigationTitle("ArchFusion BIM")
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
