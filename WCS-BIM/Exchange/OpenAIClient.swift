import Foundation

enum OpenAIClientError: LocalizedError {
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Could not parse AI response."
        case .httpError(let code): "OpenAI request failed (HTTP \(code))."
        }
    }
}

actor OpenAIClient {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendPrompt(_ prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            return mockResponse(for: prompt)
        }

        do {
            return try await sendResponsesAPI(prompt)
        } catch {
            return try await sendChatCompletions(prompt)
        }
    }

    private func sendResponsesAPI(_ prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw OpenAIClientError.invalidResponse
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": prompt
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw OpenAIClientError.httpError(http.statusCode)
        }
        if let text = Self.parseResponseText(data) {
            return text
        }
        throw OpenAIClientError.invalidResponse
    }

    private func sendChatCompletions(_ prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw OpenAIClientError.httpError(http.statusCode)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIClientError.invalidResponse
        }
        return content
    }

    static func parseResponseText(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let output = json["output"] as? [[String: Any]] {
            for item in output {
                if let content = item["content"] as? [[String: Any]] {
                    for block in content {
                        if let text = block["text"] as? String { return text }
                    }
                }
            }
        }
        return nil
    }

    private func mockResponse(for prompt: String) -> String {
        """
        [ArchFusion AI — offline preview]
        Add an OpenAI API key to enable live responses.

        Based on your prompt:
        • Review 3 massing options against site landmarks
        • Align structural grid to \(prompt.contains("airport") ? "24m" : "7.5–9m") bays
        • Document assumptions in the issue log
        • Export COBie draft after technical design freeze
        """
    }
}
