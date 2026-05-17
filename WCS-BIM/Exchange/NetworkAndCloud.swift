import CloudKit
import Foundation

actor CloudKitStore {
    private let container: CKContainer
    private var db: CKDatabase { container.privateCloudDatabase }

    init(containerIdentifier: String? = "iCloud.wcs.WCS-BIM") {
        if let containerIdentifier {
            container = CKContainer(identifier: containerIdentifier)
        } else {
            container = CKContainer.default()
        }
    }

    func saveProject(name: String, latitude: Double, longitude: Double, notes: String) async throws {
        let record = CKRecord(recordType: "Project")
        record["name"] = name as CKRecordValue
        record["latitude"] = latitude as CKRecordValue
        record["longitude"] = longitude as CKRecordValue
        record["notes"] = notes as CKRecordValue
        _ = try await db.save(record)
    }
}
