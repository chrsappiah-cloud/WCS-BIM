import Foundation
import SwiftData

@Model
final class ExportPackage {
    var id: UUID
    var format: String
    var fileName: String
    var createdAt: Date
    var notes: String
    var project: Project?

    init(format: String, fileName: String, notes: String = "") {
        self.id = UUID()
        self.format = format
        self.fileName = fileName
        self.createdAt = Date()
        self.notes = notes
    }
}
