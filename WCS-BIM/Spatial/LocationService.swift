import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum TrackingMode {
        case standard
        case liveLocator
    }

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var lastError: String?
    var trackingMode: TrackingMode = .standard
    var isUpdatingLocation = false
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -32.9283, longitude: 151.7817),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -32.9283, longitude: 151.7817),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        requestPermission()
        startUpdates()
    }

    func requestPermission() {
        guard !UITestConfiguration.isEnabled else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        guard !UITestConfiguration.isEnabled else { return }
        applyTrackingConfiguration()
        manager.startUpdatingLocation()
        isUpdatingLocation = true
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
        isUpdatingLocation = false
    }

    func enableLiveLocatorMode() {
        trackingMode = .liveLocator
        applyTrackingConfiguration()
        if isUpdatingLocation {
            manager.stopUpdatingLocation()
            manager.startUpdatingLocation()
        } else {
            startUpdates()
        }
    }

    func enableStandardMode() {
        trackingMode = .standard
        applyTrackingConfiguration()
    }

    private func applyTrackingConfiguration() {
        switch trackingMode {
        case .standard:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
        case .liveLocator:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 5
            manager.pausesLocationUpdatesAutomatically = false
            if #available(iOS 17.0, *) {
                manager.showsBackgroundLocationIndicator = false
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                startUpdates()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            currentLocation = location
            setMapCenter(location.coordinate)
        }
    }

    func setMapCenter(_ coordinate: CLLocationCoordinate2D) {
        mapRegion.center = coordinate
        mapCameraPosition = .region(MKCoordinateRegion(center: coordinate, span: mapRegion.span))
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
        }
    }
}
