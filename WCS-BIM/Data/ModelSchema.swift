import Foundation
import OSLog
import SwiftData

enum ArchFusionSchema {
    private static let logger = Logger(subsystem: "wcs.WCS-BIM", category: "ModelContainer")
    private static let bootstrapLock = NSLock()

    /// Single container for the XCTest app host (SwiftData rejects duplicates in-process).
    private(set) static var sharedTestContainer: ModelContainer?

    /// Eager-loaded store shared by the app entry point and tests.
    private(set) static var preloadedContainer: ModelContainer?

    static func registerPreloadedContainer(_ container: ModelContainer) {
        bootstrapLock.lock()
        defer { bootstrapLock.unlock() }
        preloadedContainer = container
        if usesIsolatedTestStore {
            sharedTestContainer = container
        }
    }

    /// Store for UI-test and emergency fallback (disk first, then in-memory).
    static func makeUITestContainer() -> ModelContainer? {
        if Thread.isMainThread {
            return try? MainActor.assumeIsolated { try makeUITestContainerThrowing() }
        }
        return try? DispatchQueue.main.sync {
            try MainActor.assumeIsolated { try makeUITestContainerThrowing() }
        }
    }

    @MainActor
    private static func makeUITestContainerThrowing() throws -> ModelContainer {
        do {
            return try openMemoryStoreThrowing(logLabel: "uitest-app")
        } catch {
            logger.warning("UI-test in-memory store failed: \(error.localizedDescription)")
        }

        let url = ephemeralStoreURL(label: "uitest-app")
        for types in [coreModels, [Project.self, Landmark.self, BIMElement.self, SiteObservation.self]] {
            do {
                return try openDiskStore(at: url, types: types)
            } catch {
                logger.warning("UI-test disk store failed: \(error.localizedDescription)")
                removeStoreFiles(at: url)
            }
        }

        throw ModelContainerBootstrapError.unavailable("uitest-app")
    }

    static let coreModels: [any PersistentModel.Type] = [
        Project.self,
        Landmark.self,
        BIMElement.self,
        DesignOption.self,
        Issue.self,
        AssetRecord.self,
        ExportPackage.self,
        AIInteraction.self,
        SiteObservation.self
    ]

    static let models: [any PersistentModel.Type] = coreModels

    static var isRunningUnderXCTest: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("-XCTest")
    }

    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// Previews and unit-test host use isolated storage. UI tests use `makeUITestContainer()` / sandbox disk.
    static var usesIsolatedTestStore: Bool {
        if UITestConfiguration.isEnabled { return false }
        return isPreview || isRunningUnderXCTest
    }

    /// Synchronous bootstrap for UI-test launches (called from `WCS_BIMApp.init`).
    static func bootstrapForUITesting() {
        guard UITestConfiguration.isEnabled else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { bootstrapForUITestingOnMainActor() }
        } else {
            DispatchQueue.main.sync { bootstrapForUITestingOnMainActor() }
        }
    }

    @MainActor
    private static func bootstrapForUITestingOnMainActor() {
        bootstrapLock.lock()
        defer { bootstrapLock.unlock() }
        guard preloadedContainer == nil else { return }
        do {
            let container = try makeUITestContainerThrowing()
            preloadedContainer = container
            logger.info("UI-test SwiftData bootstrap succeeded.")
        } catch {
            logger.error("UI-test SwiftData bootstrap failed: \(error.localizedDescription)")
        }
    }

    /// Call from tests so the store exists before the app shell loads.
    static func warmUpForTesting() {
        guard usesIsolatedTestStore else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { warmUpOnMainActor() }
        } else {
            DispatchQueue.main.sync { warmUpOnMainActor() }
        }
    }

    @MainActor
    private static func warmUpOnMainActor() {
        bootstrapLock.lock()
        defer { bootstrapLock.unlock() }
        guard sharedTestContainer == nil else { return }
        do {
            sharedTestContainer = try openIsolatedStoreThrowing()
            logger.info("SwiftData warm-up succeeded for test host.")
        } catch {
            logger.error("SwiftData warm-up failed: \(error.localizedDescription)")
        }
    }

    static func makeContainerThrowing(cloudKitEnabled: Bool? = nil) throws -> ModelContainer {
        if usesIsolatedTestStore {
            return try sharedIsolatedContainer()
        }

        let userCloudPref = UserDefaults.standard.object(forKey: "cloudKitEnabled") as? Bool
        let preferCloudKit = cloudKitEnabled ?? userCloudPref ?? true

        if preferCloudKit, let container = openCloudStore() {
            return container
        }

        for url in [defaultStoreURL, versionedStoreURL] {
            ensureParentDirectory(for: url)
            do {
                let container = try openDiskStore(at: url, types: models)
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

    static func makeVariadicContainerForTests(configuration: ModelConfiguration) throws -> ModelContainer {
        try makeVariadicContainer(configuration: configuration)
    }

    // MARK: - Isolated test / preview store

    private static func sharedIsolatedContainer() throws -> ModelContainer {
        if Thread.isMainThread {
            return try MainActor.assumeIsolated { try sharedIsolatedContainerOnMainActor() }
        }
        return try DispatchQueue.main.sync {
            try MainActor.assumeIsolated { try sharedIsolatedContainerOnMainActor() }
        }
    }

    @MainActor
    private static func sharedIsolatedContainerOnMainActor() throws -> ModelContainer {
        bootstrapLock.lock()
        defer { bootstrapLock.unlock() }
        if let sharedTestContainer {
            return sharedTestContainer
        }
        let container = try openIsolatedStoreThrowing()
        sharedTestContainer = container
        return container
    }

    @MainActor
    private static func openIsolatedStoreThrowing() throws -> ModelContainer {
        let label = isPreview ? "preview" : (UITestConfiguration.isEnabled ? "uitest" : "xctest")
        var lastError: Error?

        // In-memory core schema first — most reliable in XCTest / UI-test hosts.
        do {
            let schema = Schema(coreModels)
            let container = try ModelContainer(
                for: schema,
                configurations: localConfiguration(schema: schema, inMemoryOnly: true)
            )
            logger.info("In-memory core SwiftData ready (\(label)).")
            return container
        } catch {
            lastError = error
            logger.warning("In-memory core store failed (\(label)): \(error.localizedDescription)")
        }

        let typeSets: [[any PersistentModel.Type]] = [coreModels, models]
        for types in typeSets {
            let url = ephemeralStoreURL(label: label)
            do {
                let container = try openDiskStore(at: url, types: types)
                logger.info("Isolated SwiftData ready (\(label), \(types.count) models).")
                return container
            } catch {
                lastError = error
                logger.warning("Isolated disk store failed (\(label), \(types.count)): \(error.localizedDescription)")
                removeStoreFiles(at: url)
            }
        }

        // Per-model disk attempts (fresh URL each time).
        for type in models {
            let url = ephemeralStoreURL(label: "\(label)-\(String(describing: type))")
            do {
                let schema = Schema([type])
                let container = try ModelContainer(
                    for: schema,
                    configurations: localConfiguration(schema: schema, url: url)
                )
                logger.info("Isolated single-model SwiftData ready: \(type).")
                return container
            } catch {
                lastError = error
                removeStoreFiles(at: url)
            }
        }

        return try openMemoryStoreThrowing(logLabel: label, lastError: lastError)
    }

    private static func isolatedStoreDirectory() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appending(component: "ArchFusionSwiftData", directoryHint: .isDirectory)
    }

    private static func ephemeralStoreURL(label: String) -> URL {
        let directory = isolatedStoreDirectory()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "ArchFusion_\(label)_\(UUID().uuidString).store")
    }

    private static func openMemoryStoreThrowing(
        logLabel: String,
        lastError: Error? = nil
    ) throws -> ModelContainer {
        var lastError = lastError
        let schema = Schema(coreModels)
        let config = localConfiguration(schema: schema, inMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: config)
            logger.info("In-memory SwiftData ready (\(logLabel), variadic).")
            return container
        } catch {
            lastError = error
        }

        for types in [models, coreModels] {
            do {
                let fallbackSchema = Schema(types)
                let fallbackConfig = localConfiguration(schema: fallbackSchema, inMemoryOnly: true)
                let container = try ModelContainer(for: fallbackSchema, configurations: fallbackConfig)
                logger.info("In-memory SwiftData ready (\(logLabel), \(types.count) models).")
                return container
            } catch {
                lastError = error
            }
        }

        throw lastError ?? ModelContainerBootstrapError.unavailable(logLabel)
    }

    private static func makeVariadicContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        let schema = Schema(coreModels)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    private static func openDiskStore(
        at url: URL,
        types: [any PersistentModel.Type]
    ) throws -> ModelContainer {
        ensureParentDirectory(for: url)
        removeStoreFiles(at: url)
        let schema = Schema(types)
        let configuration = localConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: configuration)
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
        appSupportDirectory.appending(path: "ArchFusion_v11.store")
    }

    private static func localConfiguration(
        schema: Schema,
        url: URL? = nil,
        inMemoryOnly: Bool = false
    ) -> ModelConfiguration {
        if inMemoryOnly {
            return ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        return ModelConfiguration(schema: schema, url: url!, cloudKitDatabase: .none)
    }

    private static var appSupportDirectory: URL {
        if usesIsolatedTestStore {
            return FileManager.default.temporaryDirectory.appending(path: "ArchFusionTestSupport")
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
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
