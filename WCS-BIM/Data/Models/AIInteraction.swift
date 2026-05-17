import Foundation
import SwiftData

@Model
final class AIInteraction {
    var id: UUID
    var promptType: String
    var prompt: String
    var response: String
    var createdAt: Date

    init(prompt: String, response: String, promptType: String = "custom") {
        self.id = UUID()
        self.promptType = promptType
        self.prompt = prompt
        self.response = response
        self.createdAt = Date()
    }
}
