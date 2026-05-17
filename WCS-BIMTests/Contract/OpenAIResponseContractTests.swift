//
//  OpenAIResponseContractTests.swift
//  WCS-BIMTests
//
//  Tier 4 — Contract-style checks for API response parsing (no network).
//

import XCTest
@testable import WCS_BIM

final class OpenAIResponseContractTests: XCTestCase {

    func testChatCompletionJSONShapeParses() throws {
        let json = """
        {
          "choices": [
            { "message": { "content": "Three massing options for the terminal." } }
          ]
        }
        """
        let data = Data(json.utf8)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = object?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        XCTAssertEqual(content, "Three massing options for the terminal.")
    }

    func testResponsesAPIOutputShapeParses() throws {
        let json = """
        {
          "output": [
            {
              "content": [
                { "text": "Concept A: linear pier." }
              ]
            }
          ]
        }
        """
        let data = Data(json.utf8)
        XCTAssertEqual(OpenAIClient.parseResponseText(data), "Concept A: linear pier.")
    }

    func testOfflineClientReturnsDeterministicPreview() async throws {
        let client = OpenAIClient(apiKey: "")
        let response = try await client.sendPrompt("airport")
        XCTAssertTrue(response.contains("offline preview"))
    }
}
