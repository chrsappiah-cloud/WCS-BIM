import CoreLocation
import Foundation

struct SiteValuationResult: Equatable {
    let estimatedValue: Double
    let currency: String
    let confidence: Double
    let basisDescription: String
    let locality: String
    let ratePerSquareMetre: Double
    let assumedAreaSquareMetres: Double
    let propertyName: String?
}

struct SiteValuationService {
    func valuate(project: Project, address: String?, identifiedProperty: IdentifiedProperty? = nil) -> SiteValuationResult {
        let coordinate = CLLocationCoordinate2D(
            latitude: project.siteLatitude,
            longitude: project.siteLongitude
        )
        let resolvedAddress = identifiedProperty?.address ?? address ?? project.siteAddress
        let locality = localityLabel(from: resolvedAddress.nilIfEmpty)
        let area = assumedGrossFloorArea(for: project)
        let locationFactor = locationMultiplier(for: coordinate, locality: locality)
        let typeRate = baseRatePerSquareMetre(for: project.projectType)
        let rate = typeRate * locationFactor
        let value = rate * area
        let confidence = confidenceScore(
            hasAddress: !(resolvedAddress ?? "").isEmpty,
            coordinate: coordinate,
            identifiedProperty: identifiedProperty
        )

        let propertyLabel = identifiedProperty?.name ?? locality
        return SiteValuationResult(
            estimatedValue: value,
            currency: project.valuationCurrency.isEmpty ? "AUD" : project.valuationCurrency,
            confidence: confidence,
            basisDescription: "Indicative \(project.projectType.displayName.lowercased()) value for \(propertyLabel) using \(Int(area)) m² GFA at \(formattedCurrency(rate, currency: project.valuationCurrency))/m².",
            locality: locality,
            ratePerSquareMetre: rate,
            assumedAreaSquareMetres: area,
            propertyName: identifiedProperty?.name
        )
    }

    func apply(_ result: SiteValuationResult, to project: Project) {
        project.estimatedSiteValue = result.estimatedValue
        project.valuationCurrency = result.currency
        project.valuatedAt = Date()
    }

    private func assumedGrossFloorArea(for project: Project) -> Double {
        let digits = project.programSummary
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 >= 200 && $0 <= 500_000 }
        if let parsed = digits.first {
            return Double(parsed)
        }
        switch project.projectType {
        case .residential: return 450
        case .commercial: return 2_400
        case .airport: return 18_000
        case .mixedUse: return 3_600
        case .institutional: return 1_800
        }
    }

    private func baseRatePerSquareMetre(for type: ProjectType) -> Double {
        switch type {
        case .residential: return 4_200
        case .commercial: return 6_800
        case .airport: return 1_950
        case .mixedUse: return 5_600
        case .institutional: return 3_900
        }
    }

    private func locationMultiplier(for coordinate: CLLocationCoordinate2D, locality: String) -> Double {
        guard coordinate.latitude != 0 || coordinate.longitude != 0 else { return 1.0 }
        let metro = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        let distanceMetres = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: metro.latitude, longitude: metro.longitude))
        let distanceFactor = max(0.75, min(1.35, 1.2 - (distanceMetres / 2_500_000)))
        let coastalBonus = abs(coordinate.latitude) < 45 ? 1.05 : 1.0
        let localityBonus = locality.lowercased().contains("cbd") ? 1.12 : 1.0
        return distanceFactor * coastalBonus * localityBonus
    }

    private func confidenceScore(
        hasAddress: Bool,
        coordinate: CLLocationCoordinate2D,
        identifiedProperty: IdentifiedProperty?
    ) -> Double {
        guard coordinate.latitude != 0 || coordinate.longitude != 0 else { return 0.35 }
        if identifiedProperty != nil { return 0.91 }
        return hasAddress ? 0.82 : 0.68
    }

    private func localityLabel(from address: String?) -> String {
        guard let address, !address.isEmpty else { return "Unspecified locality" }
        let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if parts.count >= 2 {
            return parts[parts.count - 2]
        }
        return parts.first.map { String($0) } ?? "Unspecified locality"
    }

    private func formattedCurrency(_ value: Double, currency: String) -> String {
        let code = currency.isEmpty ? "AUD" : currency
        return value.formatted(.currency(code: code).precision(.fractionLength(0)))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
