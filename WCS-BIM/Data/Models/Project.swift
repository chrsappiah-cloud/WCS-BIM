import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var siteLatitude: Double
    var siteLongitude: Double
    var createdAt: Date
    var notes: String
    var projectTypeRaw: String
    var designStageRaw: String
    var climate: String
    var programSummary: String
    var constraintsText: String
    var siteGeometryNotes: String
    var zoningNotes: String
    var accessRoads: String
    var pedestrianFlow: String
    var surroundingContext: String

    @Relationship(deleteRule: .cascade, inverse: \Landmark.project) var landmarks: [Landmark] = []
    @Relationship(deleteRule: .cascade, inverse: \BIMElement.project) var elements: [BIMElement] = []
    @Relationship(deleteRule: .cascade, inverse: \DesignOption.project) var designOptions: [DesignOption] = []
    @Relationship(deleteRule: .cascade, inverse: \Issue.project) var issues: [Issue] = []
    @Relationship(deleteRule: .cascade, inverse: \AssetRecord.project) var assets: [AssetRecord] = []
    @Relationship(deleteRule: .cascade, inverse: \SiteObservation.project) var observations: [SiteObservation] = []
    @Relationship(deleteRule: .cascade, inverse: \ExportPackage.project) var exportPackages: [ExportPackage] = []
    @Relationship(deleteRule: .cascade, inverse: \AIInteraction.project) var aiInteractions: [AIInteraction] = []

    init(
        name: String,
        siteLatitude: Double = 0,
        siteLongitude: Double = 0,
        notes: String = "",
        projectType: ProjectType = .commercial,
        designStage: DesignStage = .concept,
        climate: String = "",
        programSummary: String = "",
        constraintsText: String = "",
        siteGeometryNotes: String = "",
        zoningNotes: String = "",
        accessRoads: String = "",
        pedestrianFlow: String = "",
        surroundingContext: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.siteLatitude = siteLatitude
        self.siteLongitude = siteLongitude
        self.createdAt = Date()
        self.notes = notes
        self.projectTypeRaw = projectType.rawValue
        self.designStageRaw = designStage.rawValue
        self.climate = climate
        self.programSummary = programSummary
        self.constraintsText = constraintsText
        self.siteGeometryNotes = siteGeometryNotes
        self.zoningNotes = zoningNotes
        self.accessRoads = accessRoads
        self.pedestrianFlow = pedestrianFlow
        self.surroundingContext = surroundingContext
    }
}

extension Project {
    var projectType: ProjectType {
        get { ProjectType(rawValue: projectTypeRaw) ?? .commercial }
        set { projectTypeRaw = newValue.rawValue }
    }

    var designStage: DesignStage {
        get { DesignStage(rawValue: designStageRaw) ?? .concept }
        set { designStageRaw = newValue.rawValue }
    }
}
