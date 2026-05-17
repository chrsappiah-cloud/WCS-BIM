import Foundation
import SwiftData

@Model
final class SiteObservation {
    var id: UUID
    var title: String
    var note: String
    var latitude: Double?
    var longitude: Double?
    var photoPath: String?
    var capturedAt: Date
    var arTransformData: Data?
    var project: Project?

    init(
        title: String,
        note: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoPath: String? = nil,
        arTransformData: Data? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.photoPath = photoPath
        self.capturedAt = Date()
        self.arTransformData = arTransformData
    }
}
