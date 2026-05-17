import UIKit

enum SitePhotoStore {
    static func save(_ image: UIImage, projectID: UUID, observationID: UUID) throws -> String {
        let directory = photosDirectory(projectID: projectID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appending(path: "\(observationID.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw StoreError.encodingFailed
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    static func load(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    private static func photosDirectory(projectID: UUID) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "SitePhotos/\(projectID.uuidString)")
    }

    enum StoreError: Error {
        case encodingFailed
    }
}
