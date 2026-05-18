import CoreLocation
import UIKit

protocol LocationSensorProviding: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    func requestPermission()
    func startUpdates()
    func stopUpdates()
}

protocol MotionSensorProviding: AnyObject {
    var isActive: Bool { get }
    var lastAcceleration: (x: Double, y: Double, z: Double)? { get }
    var lastAttitudeDegrees: (pitch: Double, roll: Double, yaw: Double)? { get }
    func start()
    func stop()
}

protocol ImageCaptureProviding {
    func captureFromLibrary(data: Data) async throws -> UIImage
}

protocol OCRProviding {
    func recognizeText(in image: UIImage) async -> String
}

protocol AIGenerationProviding: Sendable {
    var providerID: String { get }
    func generate(prompt: String, apiKey: String?) async throws -> String
}

struct CapturedSiteMedia: Sendable {
    let image: UIImage
    let ocrText: String
    let latitude: Double?
    let longitude: Double?
    let savedPath: String?
}

struct SensorSnapshot: Sendable {
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let horizontalAccuracy: Double?
    let acceleration: (x: Double, y: Double, z: Double)?
    let activeProviders: [String]
}
