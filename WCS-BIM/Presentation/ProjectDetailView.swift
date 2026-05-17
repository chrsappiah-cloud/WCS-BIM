import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var landmarkTitle = ""
    @State private var landmarkLat = 0.0
    @State private var landmarkLon = 0.0

    var body: some View {
        Form {
            Section {
                NavigationLink("Open full workspace") {
                    ProjectWorkspaceView(project: project)
                }
            }

            Section("Site") {
                TextField("Name", text: $project.name)
                TextField("Notes", text: $project.notes, axis: .vertical)
                TextField("Latitude", value: $project.siteLatitude, format: .number)
                TextField("Longitude", value: $project.siteLongitude, format: .number)
            }

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
    }
}
