import Foundation
import SwiftData

@Model
final class Landmark {
    var id: UUID
    var title: String
    var latitude: Double
    var longitude: Double
    var category: String
    var note: String
    var arAnchorTransformData: Data?

    init(
        title: String,
        latitude: Double,
        longitude: Double,
        category: String = "Landmark",
        note: String = "",
        arAnchorTransformData: Data? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.note = note
        self.arAnchorTransformData = arAnchorTransformData
    }
}
