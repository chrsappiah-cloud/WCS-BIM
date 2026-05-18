import Foundation

/// Registry of Apple ecosystem and external open API integrations.
enum APIProviderCatalog {
    enum Category: String, CaseIterable {
        case appleSensor = "Apple Sensors"
        case appleCapture = "Apple Capture"
        case appleVision = "Apple Vision"
        case externalAI = "External AI"
    }

    struct Entry: Identifiable, Sendable {
        let id: String
        let name: String
        let category: Category
        let framework: String
        let license: String
        let endpoint: String?
        let requiresKey: Bool
        let description: String
    }

    static let all: [Entry] = appleSensors + appleCapture + appleVision + externalAI

    static let appleSensors: [Entry] = [
        Entry(
            id: "apple.corelocation",
            name: "Core Location",
            category: .appleSensor,
            framework: "CoreLocation",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "GPS, geofencing, and site coordinate geo-reference."
        ),
        Entry(
            id: "apple.coremotion",
            name: "Core Motion",
            category: .appleSensor,
            framework: "CoreMotion",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "Accelerometer, gyro, and device attitude for AR stability."
        ),
        Entry(
            id: "apple.arkit",
            name: "ARKit",
            category: .appleSensor,
            framework: "ARKit / RealityKit",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "World tracking, plane detection, and AR anchors."
        ),
        Entry(
            id: "apple.mapkit",
            name: "MapKit",
            category: .appleSensor,
            framework: "MapKit",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "Site maps, markers, and realistic elevation."
        )
    ]

    static let appleCapture: [Entry] = [
        Entry(
            id: "apple.photospicker",
            name: "PhotosPicker",
            category: .appleCapture,
            framework: "PhotosUI",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "Library and camera roll image import."
        ),
        Entry(
            id: "apple.uikit.camera",
            name: "Camera Capture",
            category: .appleCapture,
            framework: "UIKit / AVFoundation",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "Live camera still capture for site observations."
        ),
        Entry(
            id: "apple.roomplan",
            name: "RoomPlan",
            category: .appleCapture,
            framework: "RoomPlan",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "LiDAR interior scanning on supported devices."
        )
    ]

    static let appleVision: [Entry] = [
        Entry(
            id: "apple.vision.ocr",
            name: "Vision OCR",
            category: .appleVision,
            framework: "Vision",
            license: "Apple SDK",
            endpoint: nil,
            requiresKey: false,
            description: "On-device text recognition for site notes."
        )
    ]

    static let externalAI: [Entry] = [
        Entry(
            id: "openai.chat",
            name: "OpenAI",
            category: .externalAI,
            framework: "URLSession",
            license: "Commercial API",
            endpoint: "https://api.openai.com/v1",
            requiresKey: true,
            description: "GPT responses and chat completions for design prompts."
        ),
        Entry(
            id: "huggingface.inference",
            name: "Hugging Face Inference",
            category: .externalAI,
            framework: "URLSession",
            license: "Open models (server)",
            endpoint: "https://api-inference.huggingface.co",
            requiresKey: true,
            description: "Open-source model inference for text generation fallback."
        ),
        Entry(
            id: "offline.templates",
            name: "Offline Templates",
            category: .externalAI,
            framework: "On-device",
            license: "MIT (app)",
            endpoint: nil,
            requiresKey: false,
            description: "Deterministic BIM prompt templates when no API key is set."
        )
    ]

    static func entries(in category: Category) -> [Entry] {
        all.filter { $0.category == category }
    }
}
