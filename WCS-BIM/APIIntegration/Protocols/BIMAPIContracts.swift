import Foundation

nonisolated struct APIProject: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var description: String?
    var location: String?
    var clientName: String?
    var status: String
    var createdAt: Date?
    var updatedAt: Date?
}

nonisolated struct APIBIMElement: Codable, Identifiable, Sendable {
    let id: String
    var projectId: String
    var externalId: String?
    var elementType: String
    var name: String?
    var levelName: String?
    var dimensions: [String: Double]
    var quantity: Double?
    var materialId: String?
}

nonisolated struct APIMaterial: Codable, Identifiable, Sendable {
    let id: String
    var projectId: String?
    var name: String
    var category: String
    var spec: [String: String]
}

nonisolated struct APIMaterialCreateRequest: Codable, Sendable {
    var projectId: String
    var name: String
    var category: String
    var spec: [String: String]
}

nonisolated struct APIMaterialTest: Codable, Identifiable, Sendable {
    let id: String
    var projectId: String
    var materialId: String?
    var testType: String
    var inputFeatures: [String: Double]
    var measuredValues: [String: Double]?
    var predictedValues: [String: Double]?
    var aiModel: String?
    var status: String
    var bimElementId: String?
}

nonisolated struct APIDesignAlternative: Codable, Identifiable, Sendable {
    let id: String
    var projectId: String
    var name: String
    var energyDemandKWhPerM2Y: Double?
    var embodiedCarbonKgCO2ePerM2: Double?
    var materials: [String: String]
}

nonisolated struct APIFabricationModule: Codable, Identifiable, Sendable {
    let id: String
    var projectId: String
    var name: String
    var process: String
    var estimatedTimeHours: Double
    var wastePercent: Double
    var qaCheckpoints: [String]
}

nonisolated struct APIMixOptimizerRequest: Codable, Sendable {
    var targetProperties: [String: Double]
    var constraints: [String: Double]
    var availableComponents: [String]
}

nonisolated struct APIMaterialPredictionRequest: Codable, Sendable {
    var target: String
    var model: String
    var inputFeatures: [String: Double]
}

nonisolated struct APIMaterialPredictionResult: Codable, Sendable {
    var target: String
    var value: Double
    var model: String
}

nonisolated struct APIMaterialsPredictionRequest: Codable, Sendable {
    var projectId: String
    var materialId: String?
    var materialType: String
    var inputFeatures: [String: Double]
}

nonisolated struct APIMaterialsPredictionResult: Codable, Sendable {
    var projectId: String
    var materialId: String?
    var prediction: [String: Double]
    var model: String
    var confidence: Double
    var explanations: [String]
}

nonisolated struct APIImageQCRequest: Codable, Sendable {
    var imageBase64: String
    var bimElementId: String?
}

nonisolated struct APIImageQCResult: Codable, Sendable {
    var bimElementId: String?
    var screening: String
    var edgeDensity: Double
    var confidence: Double
    var disclaimer: String
}

nonisolated struct APIMixOptimizerResult: Codable, Sendable {
    var mixes: [APIMixDesign]
    var rationale: String
}

nonisolated struct APIMixDesign: Codable, Sendable {
    var components: [String: Double]
    var compressiveStrengthMPa: Double
    var slumpMM: Double
    var permeability: Double?
    var co2KgPerM3: Double
    var costPerM3: Double
}

nonisolated struct APIQCReportRequest: Codable, Sendable {
    var projectId: String
    var testIds: [String]
}

nonisolated struct APIQCReportResult: Codable, Sendable {
    var markdown: String
}

nonisolated struct APIBIMLinkRequest: Codable, Sendable {
    var materialId: String
    var bimElementIds: [String]
    var testIds: [String]
}

nonisolated struct APIBIMLinkResult: Codable, Sendable {
    var projectId: String
    var materialId: String
    var linkedElements: Int
    var linkedTests: Int
}

nonisolated struct APIMaterialTestReportRequest: Codable, Sendable {
    var projectId: String
    var testIds: [String]
}

nonisolated struct APIMaterialTestReportResult: Codable, Sendable {
    var markdown: String
}

nonisolated struct APIUploadResult: Codable, Sendable {
    var path: String
    var bucket: String
    var contentType: String
    var size: Int
}

nonisolated struct APISignedURLRequest: Codable, Sendable {
    var projectId: String
    var bucket: String
    var path: String
    var expiresIn: Int
}

nonisolated struct APISignedURLResult: Codable, Sendable {
    var signedURL: URL
    var expiresIn: Int
}

nonisolated struct APIModelRecord: Codable, Identifiable, Sendable {
    let id: String
    var modelName: String
    var version: String
    var task: String
    var featureSet: [String]
    var metrics: [String: Double]
    var artifactPath: String?
    var trainedAt: Date?
    var active: Bool
    var notes: String?
}

nonisolated struct APIModelCreateRequest: Codable, Sendable {
    var modelName: String
    var version: String
    var task: String
    var featureSet: [String]
    var metrics: [String: Double]
    var artifactPath: String?
    var active: Bool
    var notes: String?
}

nonisolated struct APIRetrainRunResult: Codable, Sendable {
    var accepted: Bool
    var state: String
}

nonisolated struct APIRetrainStatus: Codable, Sendable {
    var state: String
    var startedAt: String?
    var finishedAt: String?
    var exitCode: Int?
    var message: String
}

nonisolated struct APIUserAccess: Codable, Sendable {
    var role: String
    var permissions: [String]
    var organizationId: String?

    func allows(_ permission: String) -> Bool {
        permissions.contains(permission)
    }
}

nonisolated struct APIDashboardCounts: Codable, Sendable {
    var projects: Int
    var materials: Int
    var tests: Int
    var reports: Int
    var activeModels: Int
}

nonisolated struct APIDashboard: Codable, Sendable {
    var role: String
    var permissions: [String]
    var organizationId: String?
    var counts: APIDashboardCounts
}
