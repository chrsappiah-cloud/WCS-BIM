import Foundation

/// CloudKit sharing scaffold — extend with `UICloudSharingController` when team roles are required.
struct CloudKitSharingService {
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func sharingStatusMessage() -> String {
        if isCloudKitAvailable {
            return "iCloud is available. Project metadata syncs via SwiftData + CloudKit when enabled in Signing & Capabilities."
        }
        return "Sign in to iCloud on this device to enable multi-device sync."
    }
}
