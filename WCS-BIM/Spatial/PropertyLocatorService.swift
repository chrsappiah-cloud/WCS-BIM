import CoreLocation
import Foundation
import MapKit

@MainActor
@Observable
final class PropertyLocatorService {
    var primaryProperty: IdentifiedProperty?
    var nearbyProperties: [IdentifiedProperty] = []
    var isScanning = false
    var isLiveTracking = false
    var statusText = "Ready to locate"
    var lastScanAt: Date?

    private var lastScanLocation: CLLocation?
    private let minimumRescanDistance: CLLocationDistance = 8
    private let minimumRescanInterval: TimeInterval = 12

    func startLiveTracking() {
        isLiveTracking = true
        statusText = "Acquiring GPS fix…"
    }

    func stopLiveTracking() {
        isLiveTracking = false
        statusText = "Locator paused"
    }

    func handleLocationUpdate(_ location: CLLocation) async {
        guard isLiveTracking else { return }
        guard shouldRescan(for: location) else { return }
        await scan(at: location, reason: "Live GPS update")
    }

    func scan(at location: CLLocation, reason: String = "Manual scan") async {
        isScanning = true
        statusText = "Identifying property…"
        defer { isScanning = false }

        let geocoder = CLGeocoder()
        var candidates: [IdentifiedProperty] = []

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                candidates.append(IdentifiedProperty.from(placemark: placemark, relativeTo: location))
            }
        } catch {
            statusText = "Address lookup failed — using coordinates."
        }

        let searchCandidates = await searchNearbyProperties(at: location)
        candidates.append(contentsOf: searchCandidates)

        let ranked = rankCandidates(candidates, relativeTo: location)
        nearbyProperties = Array(ranked.prefix(6))
        primaryProperty = nearbyProperties.first
        lastScanLocation = location
        lastScanAt = Date()

        if let primaryProperty {
            statusText = "\(reason): \(primaryProperty.name)"
        } else {
            statusText = "No named property found — refine with search or manual pin."
        }
    }

    func selectProperty(_ property: IdentifiedProperty) {
        primaryProperty = property
        statusText = "Selected \(property.name)"
    }

    private func shouldRescan(for location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 120 else {
            statusText = "Waiting for accurate GPS (\(Int(max(location.horizontalAccuracy, 0))) m)…"
            return false
        }

        guard let lastScanLocation else { return true }

        if location.distance(from: lastScanLocation) >= minimumRescanDistance {
            return true
        }

        if let lastScanAt, Date().timeIntervalSince(lastScanAt) >= minimumRescanInterval {
            return true
        }

        return false
    }

    private func searchNearbyProperties(at location: CLLocation) async -> [IdentifiedProperty] {
        let coordinate = location.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )

        async let addressHits = search(query: formattedCoordinateQuery(for: location), region: region, relativeTo: location)
        async let buildingHits = search(query: "building", region: region, relativeTo: location)
        async let estateHits = search(query: "property", region: region, relativeTo: location)

        let merged = await addressHits + buildingHits + estateHits
        var seen = Set<String>()
        return merged.filter { property in
            let key = "\(property.name)|\(property.address)"
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return property.distanceMetres <= 150
        }
    }

    private func search(
        query: String,
        region: MKCoordinateRegion,
        relativeTo location: CLLocation
    ) async -> [IdentifiedProperty] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.compactMap { IdentifiedProperty.from(mapItem: $0, relativeTo: location) }
        } catch {
            return []
        }
    }

    private func rankCandidates(_ candidates: [IdentifiedProperty], relativeTo location: CLLocation) -> [IdentifiedProperty] {
        candidates.sorted { lhs, rhs in
            let lhsScore = score(lhs, relativeTo: location)
            let rhsScore = score(rhs, relativeTo: location)
            if lhsScore == rhsScore {
                return lhs.distanceMetres < rhs.distanceMetres
            }
            return lhsScore > rhsScore
        }
    }

    private func score(_ property: IdentifiedProperty, relativeTo location: CLLocation) -> Double {
        var score = 100.0 - min(property.distanceMetres, 100)
        if property.source == "reverse_geocode" { score += 25 }
        if !property.address.isEmpty { score += 15 }
        if property.name.lowercased() != property.address.lowercased() { score += 8 }
        if property.distanceMetres <= location.horizontalAccuracy { score += 20 }
        return score
    }

    private func formattedCoordinateQuery(for location: CLLocation) -> String {
        String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
    }
}
