import CoreLocation
import MapKit
import SwiftUI

struct LiveLocatorMapView: View {
    let userLocation: CLLocation?
    let siteCoordinate: CLLocationCoordinate2D
    let identifiedProperty: IdentifiedProperty?
    @Binding var cameraPosition: MapCameraPosition
    var isScanning: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                if let userLocation {
                    MapCircle(
                        center: userLocation.coordinate,
                        radius: max(userLocation.horizontalAccuracy, 12)
                    )
                    .foregroundStyle(WCSColor.primary.opacity(0.12))
                    .stroke(WCSColor.primary.opacity(0.35), lineWidth: 1)
                }

                if let property = identifiedProperty {
                    Marker(property.name, coordinate: property.coordinate)
                        .tint(WCSColor.secondary)
                } else if siteCoordinate.latitude != 0 || siteCoordinate.longitude != 0 {
                    Marker("Site", coordinate: siteCoordinate)
                        .tint(WCSColor.primary)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .accessibilityIdentifier("site.location.liveMap")

            if isScanning {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning…")
                        .font(WCSFont.caption(11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(10)
                .accessibilityIdentifier("site.location.scanningBadge")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                .stroke(WCSColor.separator.opacity(0.35), lineWidth: 1)
        )
    }
}
