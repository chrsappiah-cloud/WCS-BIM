import CoreLocation
import Foundation
import MapKit

struct IdentifiedProperty: Identifiable, Equatable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: String
    let distanceMetres: Double
    let accuracyMetres: Double
    let source: String

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        coordinate: CLLocationCoordinate2D,
        category: String = "Property",
        distanceMetres: Double = 0,
        accuracyMetres: Double = 0,
        source: String = "gps"
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.category = category
        self.distanceMetres = distanceMetres
        self.accuracyMetres = accuracyMetres
        self.source = source
    }

    static func == (lhs: IdentifiedProperty, rhs: IdentifiedProperty) -> Bool {
        lhs.id == rhs.id
    }

    static func from(placemark: CLPlacemark, relativeTo location: CLLocation) -> IdentifiedProperty {
        let coordinate = placemark.location?.coordinate ?? location.coordinate
        let propertyLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let address = Self.formattedAddress(from: placemark)
        let streetLine = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let name = placemark.name
            ?? placemark.areasOfInterest?.first
            ?? streetLine.nilIfEmpty
            ?? (address.isEmpty ? "Identified site" : "Site at \(address)")
        let category = placemark.areasOfInterest?.first ?? placemark.locality ?? "Property"

        return IdentifiedProperty(
            name: name,
            address: address,
            coordinate: coordinate,
            category: category,
            distanceMetres: location.distance(from: propertyLocation),
            accuracyMetres: location.horizontalAccuracy,
            source: "reverse_geocode"
        )
    }

    static func from(mapItem: MKMapItem, relativeTo location: CLLocation) -> IdentifiedProperty? {
        guard let itemLocation = mapItem.placemark.location else { return nil }
        let address = formattedAddress(from: mapItem.placemark)
        let title = mapItem.name ?? address
        return IdentifiedProperty(
            name: title,
            address: address.isEmpty ? title : address,
            coordinate: itemLocation.coordinate,
            category: mapItem.pointOfInterestCategory?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "Place",
            distanceMetres: location.distance(from: itemLocation),
            accuracyMetres: location.horizontalAccuracy,
            source: "map_search"
        )
    }

    static func formattedAddress(from placemark: CLPlacemark) -> String {
        [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
