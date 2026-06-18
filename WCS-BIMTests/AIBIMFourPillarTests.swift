import XCTest
@testable import WCS_BIM

final class AIBIMFourPillarTests: XCTestCase {
    func testMixOptimizerReturnsThreeConstrainedOptions() {
        let mixes = AIBIMFourPillarService.optimizeMix(
            targetStrength: 45,
            maximumCarbon: 300,
            maximumCost: 190
        )

        XCTAssertEqual(mixes.count, 3)
        XCTAssertTrue(mixes.allSatisfy { $0.strengthMPa >= 45 })
        XCTAssertTrue(mixes.allSatisfy { $0.carbonKG <= 300 })
        XCTAssertTrue(mixes.allSatisfy { $0.costPerM3 <= 190 })
    }

    func testDesignCopilotMapsImportedElements() {
        let project = Project(name: "Copilot Test")
        let element = BIMElement(
            name: "WAL-001",
            elementType: "Wall",
            width: 0.2,
            height: 3,
            depth: 5,
            material: "Concrete",
            level: 0,
            family: "Wall"
        )
        project.elements.append(element)

        let strategies = AIBIMFourPillarService.designStrategies(for: project)

        XCTAssertEqual(strategies.count, 3)
        XCTAssertTrue(strategies.allSatisfy { $0.mappedElements.contains(element.guid) })
    }

    func testQCReportIncludesNonConformanceAndBIMLink() {
        let project = Project(name: "QA Test")
        let test = MaterialTestRecord(
            testType: "compressive_strength",
            aiModel: "RF",
            status: "Non-conforming",
            elementGUID: "WAL-GUID-001"
        )

        let report = AIBIMFourPillarService.qcReport(tests: [test], project: project)

        XCTAssertTrue(report.contains("1 non-conformance"))
        XCTAssertTrue(report.contains("WAL-GUID-001"))
    }

    func testMaterialsPredictionContractRoundTrips() throws {
        let result = APIMaterialsPredictionResult(
            projectId: "project-1",
            materialId: "material-1",
            prediction: ["compressive_strength_mpa": 31.8],
            model: "gradient_boosting",
            confidence: 0.86,
            explanations: ["Lower water-to-binder ratio improved predicted strength."]
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(APIMaterialsPredictionResult.self, from: data)

        XCTAssertEqual(decoded.projectId, "project-1")
        XCTAssertEqual(decoded.materialId, "material-1")
        XCTAssertEqual(decoded.prediction["compressive_strength_mpa"], 31.8)
        XCTAssertEqual(decoded.model, "gradient_boosting")
        XCTAssertEqual(decoded.confidence, 0.86)
    }

    func testBIMLinkContractRoundTrips() throws {
        let result = APIBIMLinkResult(
            projectId: "project-1",
            materialId: "material-1",
            linkedElements: 2,
            linkedTests: 3
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(APIBIMLinkResult.self, from: data)

        XCTAssertEqual(decoded.projectId, "project-1")
        XCTAssertEqual(decoded.materialId, "material-1")
        XCTAssertEqual(decoded.linkedElements, 2)
        XCTAssertEqual(decoded.linkedTests, 3)
    }

    func testMixOptimizerAPIContractRoundTrips() throws {
        let result = APIMixOptimizerResult(
            mixes: [
                APIMixDesign(
                    components: ["cement_kg": 300, "water_kg": 150],
                    compressiveStrengthMPa: 48,
                    slumpMM: 100,
                    permeability: nil,
                    co2KgPerM3: 260,
                    costPerM3: 175
                )
            ],
            rationale: "Optimized against the registered strength surrogate."
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(APIMixOptimizerResult.self, from: data)

        XCTAssertEqual(decoded.mixes.count, 1)
        XCTAssertEqual(decoded.mixes[0].compressiveStrengthMPa, 48)
        XCTAssertEqual(decoded.rationale, result.rationale)
    }
}
