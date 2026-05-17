import Foundation
import SwiftData

@Model
final class BIMElement {
    var id: UUID
    var name: String
    var elementType: String
    var width: Double
    var height: Double
    var depth: Double
    var material: String
    var level: Int
    var family: String
    var guid: String
    var designStageRaw: String
    var zone: String
    var posX: Double
    var posY: Double
    var posZ: Double
    var project: Project?

    init(
        name: String,
        elementType: String,
        width: Double,
        height: Double,
        depth: Double,
        material: String,
        level: Int,
        family: String,
        designStage: DesignStage = .concept,
        zone: String = "",
        posX: Double = 0,
        posY: Double = 0,
        posZ: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.elementType = elementType
        self.width = width
        self.height = height
        self.depth = depth
        self.material = material
        self.level = level
        self.family = family
        self.guid = UUID().uuidString
        self.designStageRaw = designStage.rawValue
        self.zone = zone
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
    }
}

extension BIMElement {
    var designStage: DesignStage {
        get { DesignStage(rawValue: designStageRaw) ?? .concept }
        set { designStageRaw = newValue.rawValue }
    }
}
