import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct SiteCaptureView: View {
    @State private var locationService = LocationService()
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var selectedProjectID: UUID?

    private var selectedProject: Project? {
        guard let selectedProjectID else { return projects.first }
        return projects.first { $0.id == selectedProjectID } ?? projects.first
    }

    var body: some View {
        @Bindable var locationService = locationService
        Map(position: $locationService.mapCameraPosition) {
            ForEach(selectedProject?.landmarks ?? [], id: \.id) { landmark in
                Marker(landmark.title, coordinate: CLLocationCoordinate2D(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                ))
                .tint(.red)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .navigationTitle("Site Capture")
        .accessibilityIdentifier("site.capture.screen")
        .toolbar {
            if !projects.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Project", selection: $selectedProjectID) {
                        ForEach(projects, id: \.id) { project in
                            Text(project.name).tag(Optional(project.id))
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                Text("Record location, landmarks, and site context")
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                if let project = selectedProject {
                    NavigationLink("Full site capture") {
                        SiteCaptureSection(project: project, viewModel: ProjectDetailViewModel())
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .onAppear {
            selectedProjectID = projects.first?.id
            centerMapOnProject()
        }
        .onChange(of: selectedProjectID) { _, _ in centerMapOnProject() }
    }

    private func centerMapOnProject() {
        guard let project = selectedProject,
              project.siteLatitude != 0 || project.siteLongitude != 0 else { return }
        locationService.setMapCenter(CLLocationCoordinate2D(
            latitude: project.siteLatitude,
            longitude: project.siteLongitude
        ))
    }
}
