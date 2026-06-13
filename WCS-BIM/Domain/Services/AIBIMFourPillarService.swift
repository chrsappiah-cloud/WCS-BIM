import Foundation

struct MixDesignProposal: Identifiable {
    let id = UUID()
    let name: String
    let model: String
    let strengthMPa: Double
    let slumpMM: Double
    let carbonKG: Double
    let costPerM3: Double
    let composition: String
}

struct DesignStrategyProposal: Identifiable {
    let id = UUID()
    let name: String
    let summary: String
    let energyDemand: Double
    let embodiedCarbon: Double
    let daylight: String
    let acoustics: String
    let mappedElements: String
}

struct FabricationModuleProposal: Identifiable {
    let id = UUID()
    let name: String
    let process: String
    let elementGUIDs: String
    let fabricationHours: Double
    let wastePercent: Double
    let qaCheckpoints: String
    let risk: String
}

enum AIBIMFourPillarService {
    static func optimizeMix(
        targetStrength: Double,
        maximumCarbon: Double,
        maximumCost: Double
    ) -> [MixDesignProposal] {
        let strength = max(20, targetStrength)
        let carbon = max(120, maximumCarbon)
        let cost = max(80, maximumCost)
        return [
            MixDesignProposal(
                name: "Low-carbon SCM",
                model: "MFA-ANN",
                strengthMPa: strength + 4,
                slumpMM: 110,
                carbonKG: min(carbon, 225),
                costPerM3: min(cost, 168),
                composition: "Cement 240, SCM 155, water 155, aggregate 1,790, admixture 5 kg/m3"
            ),
            MixDesignProposal(
                name: "Balanced performance",
                model: "Random Forest",
                strengthMPa: strength + 8,
                slumpMM: 95,
                carbonKG: min(carbon, 275),
                costPerM3: min(cost, 154),
                composition: "Cement 310, SCM 90, water 160, aggregate 1,770, admixture 4 kg/m3"
            ),
            MixDesignProposal(
                name: "High durability",
                model: "SVM-RBF",
                strengthMPa: strength + 14,
                slumpMM: 125,
                carbonKG: min(carbon, 315),
                costPerM3: min(cost, 182),
                composition: "Cement 330, SCM 110, water 150, aggregate 1,735, admixture 7 kg/m3"
            )
        ]
    }

    static func designStrategies(for project: Project) -> [DesignStrategyProposal] {
        let elementIDs = project.elements.prefix(4).map(\.guid).joined(separator: ", ")
        let mapped = elementIDs.isEmpty ? "Apply after IFC/BIM element import" : elementIDs
        return [
            DesignStrategyProposal(
                name: "Passive low-carbon envelope",
                summary: "High-performance envelope, external shading, and low-carbon concrete frame.",
                energyDemand: 42,
                embodiedCarbon: 385,
                daylight: "High, with glare control",
                acoustics: "High",
                mappedElements: mapped
            ),
            DesignStrategyProposal(
                name: "Hybrid timber structure",
                summary: "Mass-timber floors with optimized concrete cores and modular facade panels.",
                energyDemand: 48,
                embodiedCarbon: 295,
                daylight: "Medium-high",
                acoustics: "Medium; detailing required",
                mappedElements: mapped
            ),
            DesignStrategyProposal(
                name: "DFMA modular system",
                summary: "Repeatable structural bays, prefabricated services, and demountable envelope.",
                energyDemand: 51,
                embodiedCarbon: 340,
                daylight: "Medium",
                acoustics: "High with factory QA",
                mappedElements: mapped
            )
        ]
    }

    static func fabricationPlan(for project: Project) -> [FabricationModuleProposal] {
        let elements = project.elements
        let first = elements.prefix(max(1, elements.count / 2)).map(\.guid).joined(separator: ",")
        let second = elements.dropFirst(max(1, elements.count / 2)).map(\.guid).joined(separator: ",")
        return [
            FabricationModuleProposal(
                name: "Primary structural module",
                process: "Precast / rebar bending",
                elementGUIDs: first,
                fabricationHours: 38,
                wastePercent: 4.5,
                qaCheckpoints: "Rebar scan; dimensional check; strength release",
                risk: "Coordinate lifting inserts and transport envelope"
            ),
            FabricationModuleProposal(
                name: "Envelope cassette",
                process: "CNC",
                elementGUIDs: second,
                fabricationHours: 24,
                wastePercent: 6.0,
                qaCheckpoints: "CNC tolerance; seal inspection; trial fit",
                risk: "Confirm interface tolerances before production"
            )
        ]
    }

    static func qcReport(tests: [MaterialTestRecord], project: Project) -> String {
        let failures = tests.filter { $0.status == "Non-conforming" }
        let rows = tests.map {
            "- \($0.testType) | \($0.aiModel) | \($0.status) | BIM: \($0.elementGUID.isEmpty ? "Unlinked" : $0.elementGUID)"
        }.joined(separator: "\n")
        return """
        # \(project.name) QA Report

        ## Summary
        \(tests.count) material tests reviewed; \(failures.count) non-conformance(s).

        ## Non-conformances
        \(failures.isEmpty ? "No non-conforming results recorded." : failures.map(\.testType).joined(separator: ", "))

        ## Detailed Results
        \(rows.isEmpty ? "No tests recorded." : rows)

        ## Recommendations
        Verify standards and acceptance criteria with the responsible engineer. Schedule confirmatory testing for every non-conforming result before updating linked BIM elements.
        """
    }
}
