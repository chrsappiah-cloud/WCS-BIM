import MapKit
import SwiftUI

struct LandmarkMapView: View {
    let landmarks: [Landmark]
    let siteCoordinate: CLLocationCoordinate2D
    var userLocation: CLLocation? = nil
    var identifiedPropertyCoordinate: CLLocationCoordinate2D? = nil
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition) {
            if userLocation != nil {
                UserAnnotation()
            }

            if let userLocation {
                MapCircle(
                    center: userLocation.coordinate,
                    radius: max(userLocation.horizontalAccuracy, 10)
                )
                .foregroundStyle(WCSColor.primary.opacity(0.1))
                .stroke(WCSColor.primary.opacity(0.3), lineWidth: 1)
            }

            if let identifiedPropertyCoordinate {
                Marker("Property", coordinate: identifiedPropertyCoordinate)
                    .tint(WCSColor.secondary)
            } else if siteCoordinate.latitude != 0 || siteCoordinate.longitude != 0 {
                Marker("Site", coordinate: siteCoordinate)
                    .tint(WCSColor.primary)
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
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
