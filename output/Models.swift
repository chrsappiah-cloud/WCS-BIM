import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    var siteLatitude: Double
    var siteLongitude: Double
    var notes: String

    @Relationship(deleteRule: .cascade) var landmarks: [Landmark] = []
    @Relationship(deleteRule: .cascade) var elements: [BIMElement] = []
    @Relationship(deleteRule: .cascade) var issues: [Issue] = []
    @Relationship(deleteRule: .cascade) var designOptions: [DesignOption] = []
    @Relationship(deleteRule: .cascade) var assets: [AssetRecord] = []
    @Relationship(deleteRule: .cascade) var exports: [ExportPackage] = []
    @Relationship(deleteRule: .cascade) var aiInteractions: [AIInteraction] = []

    init(name: String, siteLatitude: Double = 0, siteLongitude: Double = 0, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.siteLatitude = siteLatitude
        self.siteLongitude = siteLongitude
        self.notes = notes
    }
}

@Model
final class Landmark {
    var id: UUID
    var title: String
    var latitude: Double
    var longitude: Double
    var category: String
    var note: String

    init(title: String, latitude: Double, longitude: Double, category: String = "Landmark", note: String = "") {
        self.id = UUID()
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.note = note
    }
}

@Model
final class BIMElement {
    var id: UUID
    var name: String
    var type: String
    var width: Double
    var height: Double
    var depth: Double
    var material: String
    var level: Int
    var family: String
    var guid: String

    init(name: String, type: String, width: Double, height: Double, depth: Double, material: String, level: Int, family: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.width = width
        self.height = height
        self.depth = depth
        self.material = material
        self.level = level
        self.family = family
        self.guid = UUID().uuidString
    }
}

@Model
final class Issue {
    var id: UUID
    var title: String
    var details: String
    var severity: String
    var status: String
    var elementGuid: String
    var createdAt: Date

    init(title: String, details: String, severity: String, status: String = "Open", elementGuid: String = "") {
        self.id = UUID()
        self.title = title
        self.details = details
        self.severity = severity
        self.status = status
        self.elementGuid = elementGuid
        self.createdAt = .now
    }
}

@Model
final class DesignOption {
    var id: UUID
    var title: String
    var summary: String
    var score: Double
    var aiPrompt: String
    var createdAt: Date

    init(title: String, summary: String, score: Double = 0, aiPrompt: String = "") {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.score = score
        self.aiPrompt = aiPrompt
        self.createdAt = .now
    }
}

@Model
final class AssetRecord {
    var id: UUID
    var assetTag: String
    var location: String
    var system: String
    var manufacturer: String
    var model: String
    var warrantyEnd: Date?

    init(assetTag: String, location: String, system: String, manufacturer: String = "", model: String = "", warrantyEnd: Date? = nil) {
        self.id = UUID()
        self.assetTag = assetTag
        self.location = location
        self.system = system
        self.manufacturer = manufacturer
        self.model = model
        self.warrantyEnd = warrantyEnd
    }
}

@Model
final class ExportPackage {
    var id: UUID
    var format: String
    var path: String
    var createdAt: Date

    init(format: String, path: String) {
        self.id = UUID()
        self.format = format
        self.path = path
        self.createdAt = .now
    }
}

@Model
final class AIInteraction {
    var id: UUID
    var prompt: String
    var response: String
    var createdAt: Date

    init(prompt: String, response: String) {
        self.id = UUID()
        self.prompt = prompt
        self.response = response
        self.createdAt = .now
    }
}
