import Foundation

struct OfflineTemplateAIProvider: AIGenerationProviding {
    let providerID = "offline.templates"

    func generate(prompt: String, apiKey: String?) async throws -> String {
        let snippet = String(prompt.prefix(120))
        return """
        Offline BIM assistant (no API key):
        - Review zoning and circulation for the active site.
        - Propose two massing options with core and shell separation.
        - Flag coordination risks for structure vs. MEP zones.

        Prompt excerpt: \(snippet)
        """
    }
}
