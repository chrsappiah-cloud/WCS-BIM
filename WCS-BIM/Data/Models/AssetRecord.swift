import Foundation
import SwiftData

@Model
final class AssetRecord {
    var id: UUID
    var assetName: String
    var location: String
    var system: String
    var manufacturer: String
    var productModel: String
    var warrantyNotes: String
    var warrantyEnd: Date?
    var maintenanceClass: String
    var guid: String
    var linkedElementGUID: String?

    init(
        assetName: String,
        location: String = "",
        system: String = "",
        manufacturer: String = "",
        productModel: String = "",
        warrantyNotes: String = "",
        warrantyEnd: Date? = nil,
        maintenanceClass: String = "",
        linkedElementGUID: String? = nil
    ) {
        self.id = UUID()
        self.assetName = assetName
        self.location = location
        self.system = system
        self.manufacturer = manufacturer
        self.productModel = productModel
        self.warrantyNotes = warrantyNotes
        self.warrantyEnd = warrantyEnd
        self.maintenanceClass = maintenanceClass
        self.guid = UUID().uuidString
        self.linkedElementGUID = linkedElementGUID
    }
}

extension AssetRecord {
    var assetTag: String {
        get { assetName }
        set { assetName = newValue }
    }
}
