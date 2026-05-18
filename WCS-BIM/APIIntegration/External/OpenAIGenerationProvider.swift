import Foundation

struct OpenAIGenerationProvider: AIGenerationProviding {
    let providerID = "openai.chat"

    func generate(prompt: String, apiKey: String?) async throws -> String {
        let key = apiKey ?? ""
        let client = OpenAIClient(apiKey: key)
        return try await client.sendPrompt(prompt)
    }
}
