import CoreLocation
import SwiftData
import SwiftUI

struct ARSiteSection: View {
    @Bindable var project: Project
    @Bindable var viewModel: ProjectDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var markerTitle = "AR Marker"

    var body: some View {
        ZStack(alignment: .bottom) {
            SiteARView(markers: $viewModel.arMarkers) { transform in
                let marker = ARPlacedMarker(title: markerTitle, transform: transform)
                viewModel.arMarkers.append(marker)

                if let loc = locationService.currentLocation {
                    let landmark = Landmark(
                        title: markerTitle,
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        category: "AR Pin",
                        note: "Placed in AR session",
                        arAnchorTransformData: transform.encodedData
                    )
                    project.landmarks.append(landmark)
                    modelContext.insert(landmark)
                }

                let observation = SiteObservation(
                    title: markerTitle,
                    note: "AR anchor placed",
                    latitude: locationService.currentLocation?.coordinate.latitude,
                    longitude: locationService.currentLocation?.coordinate.longitude,
                    arTransformData: transform.encodedData
                )
                project.observations.append(observation)
                modelContext.insert(observation)
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Tap a surface to place a design marker")
                    .font(.caption)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())

                HStack {
                    TextField("Marker title", text: $markerTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                    Text("\(viewModel.arMarkers.count) placed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            locationService.requestPermission()
            locationService.startUpdates()
        }
        .onDisappear {
            locationService.stopUpdates()
        }
    }
}
