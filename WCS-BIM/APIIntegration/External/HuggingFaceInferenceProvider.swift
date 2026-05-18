import Foundation

enum HuggingFaceError: LocalizedError {
    case missingKey
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingKey: "Hugging Face API key not configured."
        case .httpError(let code): "Hugging Face request failed (HTTP \(code))."
        case .invalidResponse: "Could not parse Hugging Face response."
        }
    }
}

/// Open-source model inference via Hugging Face Inference API (https://huggingface.co/docs/api-inference).
struct HuggingFaceInferenceProvider: AIGenerationProviding {
    let providerID = "huggingface.inference"
  private let modelID: String

    init(modelID: String = "HuggingFaceH4/zephyr-7b-beta") {
        self.modelID = modelID
    }

    func generate(prompt: String, apiKey: String?) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw HuggingFaceError.missingKey
        }

        let url = URL(string: "https://api-inference.huggingface.co/models/\(modelID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": ["max_new_tokens": 512, "return_full_text": false]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw HuggingFaceError.httpError(http.statusCode)
        }

        if let text = parseGeneratedText(data) {
            return text
        }
        throw HuggingFaceError.invalidResponse
    }

    private func parseGeneratedText(_ data: Data) -> String? {
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = array.first,
           let text = first["generated_text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = object["generated_text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(data: data, encoding: .utf8)
    }
}
