import Foundation
import SwiftData

@Model
final class Issue {
    var id: UUID
    var title: String
    var details: String
    var severity: String
    var status: String
    var zone: String
    var elementGuid: String
    var createdAt: Date
    var project: Project?

    init(
        title: String,
        details: String = "",
        severity: String = "Medium",
        status: String = "Open",
        zone: String = "",
        elementGuid: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.severity = severity
        self.status = status
        self.zone = zone
        self.elementGuid = elementGuid
        self.createdAt = Date()
    }
}
