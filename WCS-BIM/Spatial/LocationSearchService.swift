import CoreLocation
import Foundation
import MapKit

struct LocationSearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let fullAddress: String

    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class LocationSearchService {
    var searchResults: [LocationSearchResult] = []
    var isSearching = false
    var lastError: String?

    func search(query: String, near coordinate: CLLocationCoordinate2D? = nil) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            searchResults = []
            lastError = "Enter at least 3 characters to search."
            return
        }

        isSearching = true
        lastError = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = response.mapItems.compactMap { item in
                guard let location = item.placemark.location else { return nil }
                let title = item.name ?? item.placemark.title ?? trimmed
                let subtitle = formattedPlacemark(item.placemark)
                return LocationSearchResult(
                    title: title,
                    subtitle: subtitle,
                    coordinate: location.coordinate,
                    fullAddress: subtitle.isEmpty ? title : subtitle
                )
            }
            if searchResults.isEmpty {
                lastError = "No locations matched that search."
            }
        } catch {
            searchResults = []
            lastError = error.localizedDescription
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return formattedPlacemark(placemark)
        } catch {
            return nil
        }
    }

    private func formattedPlacemark(_ placemark: CLPlacemark) -> String {
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
