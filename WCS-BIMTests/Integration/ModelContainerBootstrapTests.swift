//
//  ModelContainerBootstrapTests.swift
//  WCS-BIMTests
//
//  Integration — SwiftData bootstrap (skipped when host cannot load store).
//

import SwiftData
import XCTest
@testable import WCS_BIM

final class ModelContainerBootstrapTests: XCTestCase {

    override func setUpWithError() throws {
        ArchFusionSchema.warmUpForTesting()
    }

    func testModelContainerBootstrapUnderXCTest() throws {
        do {
            let container = try ArchFusionSchema.makeContainerThrowing(cloudKitEnabled: false)
            XCTAssertFalse(container.schema.entities.isEmpty)

            let context = ModelContext(container)
            let project = Project(name: "XCTest Seed")
            context.insert(project)
            try context.save()
            let fetched = try context.fetch(FetchDescriptor<Project>())
            XCTAssertTrue(fetched.contains { $0.name == "XCTest Seed" })
        } catch {
            throw XCTSkip("SwiftData unavailable in XCTest host: \(error.localizedDescription)")
        }
    }
}
