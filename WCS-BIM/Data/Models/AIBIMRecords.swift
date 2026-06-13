import Foundation
import SwiftData

@Model
final class MaterialRecord {
    var id: UUID
    var name: String
    var category: String
    var specificationJSON: String
    var createdAt: Date
    var project: Project?

    init(name: String, category: String, specificationJSON: String = "{}") {
        self.id = UUID()
        self.name = name
        self.category = category
        self.specificationJSON = specificationJSON
        self.createdAt = Date()
    }
}

@Model
final class MaterialTestRecord {
    var id: UUID
    var testType: String
    var inputFeaturesJSON: String
    var measuredValuesJSON: String
    var predictedValuesJSON: String
    var aiModel: String
    var status: String
    var elementGUID: String
    var createdAt: Date
    var project: Project?

    init(
        testType: String,
        inputFeaturesJSON: String = "{}",
        measuredValuesJSON: String = "{}",
        predictedValuesJSON: String = "{}",
        aiModel: String = "RF",
        status: String = "Pending",
        elementGUID: String = ""
    ) {
        self.id = UUID()
        self.testType = testType
        self.inputFeaturesJSON = inputFeaturesJSON
        self.measuredValuesJSON = measuredValuesJSON
        self.predictedValuesJSON = predictedValuesJSON
        self.aiModel = aiModel
        self.status = status
        self.elementGUID = elementGUID
        self.createdAt = Date()
    }
}

@Model
final class FabricationModuleRecord {
    var id: UUID
    var name: String
    var process: String
    var elementGUIDs: String
    var fabricationHours: Double
    var wastePercent: Double
    var qaCheckpoints: String
    var risk: String
    var createdAt: Date
    var project: Project?

    init(
        name: String,
        process: String,
        elementGUIDs: String = "",
        fabricationHours: Double,
        wastePercent: Double,
        qaCheckpoints: String,
        risk: String
    ) {
        self.id = UUID()
        self.name = name
        self.process = process
        self.elementGUIDs = elementGUIDs
        self.fabricationHours = fabricationHours
        self.wastePercent = wastePercent
        self.qaCheckpoints = qaCheckpoints
        self.risk = risk
        self.createdAt = Date()
    }
}
