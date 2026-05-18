import XCTest
@testable import WCS_BIM

@MainActor
final class APIIntegrationTests: XCTestCase {
    func testCatalogIncludesAppleAndExternalProviders() {
        let ids = Set(APIProviderCatalog.all.map(\.id))
        XCTAssertTrue(ids.contains("apple.corelocation"))
        XCTAssertTrue(ids.contains("apple.coremotion"))
        XCTAssertTrue(ids.contains("apple.uikit.camera"))
        XCTAssertTrue(ids.contains("apple.vision.ocr"))
        XCTAssertTrue(ids.contains("openai.chat"))
        XCTAssertTrue(ids.contains("huggingface.inference"))
        XCTAssertTrue(ids.contains("offline.templates"))
    }

    func testOfflineAIWorksWithoutAPIKey() async throws {
        let provider = OfflineTemplateAIProvider()
        let text = try await provider.generate(prompt: "Test prompt", apiKey: nil)
        XCTAssertTrue(text.contains("Offline BIM assistant"))
    }

    func testHubPrefersSelectedAIProvider() async {
        let defaults = UserDefaults.standard
        let prior = defaults.string(forKey: "preferredAIProvider")
        defer {
            if let prior {
                defaults.set(prior, forKey: "preferredAIProvider")
            } else {
                defaults.removeObject(forKey: "preferredAIProvider")
            }
        }

        defaults.set("offline.templates", forKey: "preferredAIProvider")
        let hub = APIIntegrationHub()
        await hub.generateAI(prompt: "coordination checklist")

        XCTAssertTrue(hub.lastAIMessage.contains("offline.templates"))
        XCTAssertTrue(hub.lastAIMessage.contains("Offline BIM assistant"))
    }

    func testHubSensorSnapshotTracksActiveProviders() {
        let hub = APIIntegrationHub()
        hub.activateFieldSensors()
        hub.refreshSensorSnapshot()
        XCTAssertNotNil(hub.lastSensorSnapshot)
        XCTAssertTrue(hub.lastSensorSnapshot?.activeProviders.contains("apple.vision.ocr") == true)
        hub.deactivateFieldSensors()
    }
}
