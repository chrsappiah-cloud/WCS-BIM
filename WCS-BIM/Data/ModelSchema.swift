import Foundation
import OSLog
import SwiftData

enum ArchFusionSchema {
    private static let logger = Logger(subsystem: "wcs.WCS-BIM", category: "ModelContainer")

    static let coreModels: [any PersistentModel.Type] = [
        Project.self,
        Landmark.self,
        BIMElement.self,
        DesignOption.self,
        Issue.self,
        AssetRecord.self,
        ExportPackage.self,
        AIInteraction.self
    ]

    static let models: [any PersistentModel.Type] = coreModels + [SiteObservation.self]

    static var isRunningUnderXCTest: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("-XCTest")
    }

    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static func makeContainer(cloudKitEnabled: Bool? = nil) -> ModelContainer {
        if let container = try? makeContainerThrowing(cloudKitEnabled: cloudKitEnabled) {
            return container
        }
        return makeEmergencyInMemoryContainer()
    }

    static func makeContainerThrowing(cloudKitEnabled: Bool? = nil) throws -> ModelContainer {
        if isPreview || isRunningUnderXCTest {
            return try openMemoryStoreThrowing(logLabel: isPreview ? "preview" : "xctest")
        }

        let userCloudPref = UserDefaults.standard.object(forKey: "cloudKitEnabled") as? Bool
        let preferCloudKit = cloudKitEnabled ?? userCloudPref ?? true

        if preferCloudKit, let container = openCloudStore() {
            return container
        }

        for url in [defaultStoreURL, versionedStoreURL] {
            ensureParentDirectory(for: url)
            do {
                let container = try openDiskStore(at: url)
                logger.info("SwiftData ready at \(url.lastPathComponent).")
                return container
            } catch {
                logger.warning("Disk store failed at \(url.lastPathComponent): \(error.localizedDescription)")
                removeStoreFiles(at: url)
            }
        }

        logger.warning("Disk store failed; using in-memory store.")
        return try openMemoryStoreThrowing(logLabel: "fallback")
    }

    static func makeInMemoryContainer(reason: String) throws -> ModelContainer {
        try openMemoryStoreThrowing(logLabel: reason)
    }

    /// Package-visible variant for the app bootstrap to use during XCTest.
    static func makeVariadicContainerForTests(configuration: ModelConfiguration) throws -> ModelContainer {
        try makeVariadicContainer(configuration: configuration)
    }

    private static func openMemoryStoreThrowing(logLabel: String) throws -> ModelContainer {
        var lastError: Error?
        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            let container = try makeVariadicContainer(configuration: config)
            logger.info("In-memory SwiftData ready (\(logLabel), variadic).")
            return container
        } catch {
            lastError = error
            logger.error("Variadic in-memory SwiftData failed (\(logLabel)): \(error.localizedDescription)")
        }

        for types in [models, coreModels] {
            do {
                let schema = Schema(types)
                let container = try ModelContainer(for: schema, configurations: config)
                logger.info("In-memory SwiftData ready (\(logLabel), \(types.count) models).")
                return container
            } catch {
                lastError = error
                logger.error("In-memory SwiftData failed (\(logLabel), \(types.count) models): \(error.localizedDescription)")
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appending(path: "ArchFusion_ephemeral_\(UUID().uuidString).store")
        for types in [models, coreModels] {
            do {
                let container = try openDiskStore(at: url, types: types)
                logger.info("Ephemeral SwiftData ready (\(logLabel)).")
                return container
            } catch {
                lastError = error
                removeStoreFiles(at: url)
            }
        }

        throw lastError ?? ModelContainerBootstrapError.unavailable(logLabel)
    }

    private static func makeEmergencyInMemoryContainer() -> ModelContainer {
        for types in [models, coreModels] {
            let schema = Schema(types)
            if let container = try? ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ) {
                logger.warning("Using emergency in-memory SwiftData store (\(types.count) models).")
                return container
            }
        }
        for single in coreModels {
            if let container = try? ModelContainer(
                for: single,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ) {
                logger.warning("Using single-model in-memory SwiftData store (\(type(of: single))).")
                return container
            }
        }
        logger.error("No ModelContainer could be created.")
        // Last resort: one more try with a single model
        for single in coreModels {
            if let container = try? ModelContainer(
                for: single,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ) {
                return container
            }
        }
        fatalError("ArchFusion BIM: Could not create any ModelContainer.")
    }

    private static func makeVariadicContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Project.self,
            Landmark.self,
            BIMElement.self,
            DesignOption.self,
            Issue.self,
            AssetRecord.self,
            ExportPackage.self,
            AIInteraction.self,
            SiteObservation.self,
            configurations: configuration
        )
    }

    private static func openDiskStore(
        at url: URL,
        types: [any PersistentModel.Type] = models
    ) throws -> ModelContainer {
        let schema = Schema(types)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url)
        )
    }

    private static func openCloudStore() -> ModelContainer? {
        let schema = Schema(models)
        return try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        )
    }

    private static var defaultStoreURL: URL {
        appSupportDirectory.appending(path: "ArchFusion.store")
    }

    private static var versionedStoreURL: URL {
        appSupportDirectory.appending(path: "ArchFusion_v8.store")
    }

    private static var appSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }

    private static func ensureParentDirectory(for url: URL) {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func removeStoreFiles(at url: URL) {
        let fm = FileManager.default
        for path in [url.path, url.path + "-wal", url.path + "-shm"] where fm.fileExists(atPath: path) {
            try? fm.removeItem(atPath: path)
        }
    }
}

enum ModelContainerBootstrapError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let label):
            return "SwiftData ModelContainer could not be created (\(label))."
        }
    }
}
