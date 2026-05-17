import Foundation
import SwiftData

@Model
final class DesignOption {
    var id: UUID
    var title: String
    var summary: String
    var massingNotes: String
    var score: Double
    var aiPrompt: String
    var isSelected: Bool
    var createdAt: Date

    init(
        title: String,
        summary: String = "",
        massingNotes: String = "",
        score: Double = 0,
        aiPrompt: String = "",
        isSelected: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.massingNotes = massingNotes
        self.score = score
        self.aiPrompt = aiPrompt
        self.isSelected = isSelected
        self.createdAt = Date()
    }
}
