import MapKit
import SwiftUI

struct LandmarkMapView: View {
    let landmarks: [Landmark]
    let siteCoordinate: CLLocationCoordinate2D
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition) {
            if siteCoordinate.latitude != 0 || siteCoordinate.longitude != 0 {
                Marker("Site", coordinate: siteCoordinate)
                    .tint(.blue)
            }
            ForEach(landmarks, id: \.id) { landmark in
                Marker(landmark.title, coordinate: CLLocationCoordinate2D(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                ))
                .tint(.red)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
