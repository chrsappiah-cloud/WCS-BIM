import CoreLocation
import Foundation
import UIKit

/// Central coordinator for Apple sensors, capture pipelines, and AI providers.
@MainActor
@Observable
final class APIIntegrationHub {
    let location: LocationService
    let motion: AppleMotionSensorService
    let ocr: SiteNoteOCRService

    private(set) var lastCapture: CapturedSiteMedia?
    private(set) var lastSensorSnapshot: SensorSnapshot?
    private(set) var lastAIMessage = ""
    private(set) var isProcessing = false

    let aiProviders: [any AIGenerationProviding]

    private enum Storage {
        static let openAI = "openAIApiKey"
        static let huggingFace = "huggingFaceApiKey"
        static let preferredAI = "preferredAIProvider"
    }

    init(
        location: LocationService? = nil,
        motion: AppleMotionSensorService? = nil,
        ocr: SiteNoteOCRService? = nil,
        aiProviders: [any AIGenerationProviding]? = nil
    ) {
        self.location = location ?? LocationService()
        self.motion = motion ?? AppleMotionSensorService()
        self.ocr = ocr ?? SiteNoteOCRService()
        self.aiProviders = aiProviders ?? [
            OpenAIGenerationProvider(),
            HuggingFaceInferenceProvider(),
            OfflineTemplateAIProvider()
        ]
    }

    var catalog: [APIProviderCatalog.Entry] { APIProviderCatalog.all }

    func activateFieldSensors() {
        location.requestPermission()
        location.startUpdates()
        motion.start()
        refreshSensorSnapshot()
    }

    func deactivateFieldSensors() {
        location.stopUpdates()
        motion.stop()
    }

    func refreshSensorSnapshot() {
        let accel = motion.lastAcceleration
        lastSensorSnapshot = SensorSnapshot(
            timestamp: Date(),
            latitude: location.currentLocation?.coordinate.latitude,
            longitude: location.currentLocation?.coordinate.longitude,
            horizontalAccuracy: location.currentLocation?.horizontalAccuracy,
            acceleration: accel,
            activeProviders: activeProviderIDs()
        )
    }

    func activeProviderIDs() -> [String] {
        var ids: [String] = []
        if location.authorizationStatus == .authorizedWhenInUse
            || location.authorizationStatus == .authorizedAlways {
            ids.append("apple.corelocation")
        }
        if motion.isActive { ids.append("apple.coremotion") }
        ids.append("apple.vision.ocr")
        ids.append(preferredAIProviderID)
        return ids
    }

    private var preferredAIProviderID: String {
        UserDefaults.standard.string(forKey: Storage.preferredAI) ?? "openai.chat"
    }

    func processCapturedImage(
        _ image: UIImage,
        projectID: UUID,
        observationID: UUID = UUID()
    ) async -> CapturedSiteMedia {
        isProcessing = true
        defer { isProcessing = false }

        let ocrText = await ocr.recognizeText(in: image)
        let path = try? SitePhotoStore.save(image, projectID: projectID, observationID: observationID)
        let media = CapturedSiteMedia(
            image: image,
            ocrText: ocrText,
            latitude: location.currentLocation?.coordinate.latitude,
            longitude: location.currentLocation?.coordinate.longitude,
            savedPath: path
        )
        lastCapture = media
        return media
    }

    func generateAI(prompt: String) async {
        isProcessing = true
        defer { isProcessing = false }

        let ordered = orderedProviders()
        for provider in ordered {
            do {
                let key = apiKey(for: provider)
                let text = try await provider.generate(prompt: prompt, apiKey: key)
                lastAIMessage = "[\(provider.providerID)]\n\(text)"
                return
            } catch {
                continue
            }
        }
        lastAIMessage = "All AI providers failed. Check API keys in Field Systems."
    }

    func setPreferredAIProvider(_ id: String) {
        UserDefaults.standard.set(id, forKey: Storage.preferredAI)
    }

    private func orderedProviders() -> [any AIGenerationProviding] {
        let preferredID = preferredAIProviderID
        let preferred = aiProviders.first { $0.providerID == preferredID }
        let rest = aiProviders.filter { $0.providerID != preferredID }
        return [preferred].compactMap { $0 } + rest
    }

    private func apiKey(for provider: any AIGenerationProviding) -> String? {
        switch provider.providerID {
        case "openai.chat":
            let key = UserDefaults.standard.string(forKey: Storage.openAI) ?? ""
            return key.isEmpty ? nil : key
        case "huggingface.inference":
            let key = UserDefaults.standard.string(forKey: Storage.huggingFace) ?? ""
            return key.isEmpty ? nil : key
        default:
            return nil
        }
    }
}
