import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var landmarkTitle = ""
    @State private var landmarkLat = 0.0
    @State private var landmarkLon = 0.0
    @State private var showInspector = false
    @State private var inspectorParams: [InspectorParam] = []

    var body: some View {
        Form {
            Section {
                NavigationLink("Open full workspace") {
                    ProjectWorkspaceView(project: project)
                }
                .accessibilityIdentifier("project.openWorkspace")

                SecondaryButton("Edit parameters") {
                    inspectorParams = [
                        InspectorParam(key: "Name", value: project.name),
                        InspectorParam(key: "Notes", value: project.notes),
                        InspectorParam(
                            key: "Latitude",
                            value: String(format: "%.5f", project.siteLatitude)
                        ),
                        InspectorParam(
                            key: "Longitude",
                            value: String(format: "%.5f", project.siteLongitude)
                        )
                    ]
                    showInspector = true
                }
                .accessibilityIdentifier("project.editParameters")
            }

            Section("Site") {
                TextField("Name", text: $project.name)
                TextField("Notes", text: $project.notes, axis: .vertical)
            }

            SiteLocationPickerView(
                project: project,
                locationService: locationService
            )

            Section("Landmarks") {
                TextField("Title", text: $landmarkTitle)
                TextField("Lat", value: $landmarkLat, format: .number)
                TextField("Lon", value: $landmarkLon, format: .number)
                Button("Add Landmark") {
                    let landmark = Landmark(
                        title: landmarkTitle,
                        latitude: landmarkLat,
                        longitude: landmarkLon
                    )
                    project.landmarks.append(landmark)
                    modelContext.insert(landmark)
                    landmarkTitle = ""
                }
                ForEach(project.landmarks, id: \.id) { lm in
                    VStack(alignment: .leading) {
                        Text(lm.title)
                        Text("\(lm.latitude), \(lm.longitude)").font(.caption)
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .onAppear {
            locationService.requestPermission()
            locationService.startUpdates()
        }
        .sheet(isPresented: $showInspector) {
            InspectorSheet(isPresented: $showInspector, title: "Inspector", params: $inspectorParams) { saved in
                applyInspector(saved)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func applyInspector(_ params: [InspectorParam]) {
        for param in params {
            switch param.key {
            case "Name": project.name = param.value
            case "Notes": project.notes = param.value
            case "Latitude": project.siteLatitude = Double(param.value) ?? project.siteLatitude
            case "Longitude": project.siteLongitude = Double(param.value) ?? project.siteLongitude
            default: break
            }
        }
    }
}
