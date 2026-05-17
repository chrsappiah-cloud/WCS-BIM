//
//  WCS_BIMTests.swift
//  WCS-BIMTests
//
//  Tier 1 unit — fast logic tests (pre-commit / PR gate).
//

import XCTest
@testable import WCS_BIM

final class WCS_BIMTests: XCTestCase {

    func testCobieExportIncludesGUID() throws {
        let project = Project(name: "Test")
        let element = BIMElement(
            name: "WAL-PNL-001",
            elementType: "Wall",
            width: 0.2,
            height: 3,
            depth: 6,
            material: "Masonry",
            level: 0,
            family: "Wall"
        )
        project.elements.append(element)

        let csv = COBieExportService().csv(for: project)
        XCTAssertTrue(csv.contains(element.guid))
        XCTAssertTrue(csv.contains("WAL-PNL-001"))
    }

    func testIfcExportContainsProjectName() throws {
        let project = Project(name: "Airport Terminal A")
        let ifc = IFCExportService().stepFile(for: project)
        XCTAssertTrue(ifc.contains("Airport Terminal A"))
        XCTAssertTrue(ifc.contains("IFC4"))
    }

    func testDesignRulesFlagsInvalidName() throws {
        let rules = DesignRulesService()
        XCTAssertNotNil(rules.validateElementName("bad name"))
        XCTAssertNil(rules.validateElementName("WAL-PNL-001"))
    }

    func testConceptPromptIncludesLandmarks() throws {
        let prompt = AIPromptTemplates.concept(
            projectType: "Airport",
            siteContext: "Urban",
            climate: "Temperate",
            landmarks: "Control Tower",
            constraints: "Height limit 45m",
            program: "Terminal 40,000 m²"
        )
        XCTAssertTrue(prompt.contains("Control Tower"))
        XCTAssertTrue(prompt.contains("3 concept options"))
    }

    func testCloudKitSharingStatusMessage() {
        let message = CloudKitSharingService().sharingStatusMessage()
        XCTAssertFalse(message.isEmpty)
    }

    func testDesignProgramCatalogListsPackPrograms() {
        XCTAssertEqual(DesignProgramCatalog.allPrograms.count, 5)
        XCTAssertTrue(DesignProgramCatalog.allPrograms.contains { $0.name == "Airport Terminal A" })
    }

    func testDesignProgramInstallerBuildsStarterElements() {
        for program in DesignProgramCatalog.allPrograms {
            XCTAssertFalse(program.programSummary.isEmpty)
        }
        XCTAssertEqual(ParametricLibrary.presets.count, 5)
        let element = ParametricLibrary.makeElement(
            from: ParametricLibrary.presets[0],
            name: "WAL-TEST-001",
            level: 0,
            stage: .concept
        )
        XCTAssertFalse(element.guid.isEmpty)
        XCTAssertEqual(element.family, "Mass")
    }
}
