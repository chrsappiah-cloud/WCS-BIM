import Foundation

enum AIPromptType: String, CaseIterable, Identifiable {
    case concept
    case commercialPlanning
    case fmHandover
    case mixOptimizer
    case qcReport
    case designCopilot
    case fabricationPlanner

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concept: "Concept Design"
        case .commercialPlanning: "Commercial / Airport"
        case .fmHandover: "FM Handover (COBie)"
        case .mixOptimizer: "Materials Mix Optimizer"
        case .qcReport: "Automated QA Report"
        case .designCopilot: "AI Design Copilot"
        case .fabricationPlanner: "DFMA Fabrication Planner"
        }
    }
}

enum AIPromptTemplates {
    static func concept(
        projectType: String,
        siteContext: String,
        climate: String,
        landmarks: String,
        constraints: String,
        program: String
    ) -> String {
        """
        You are an architectural BIM assistant.
        Project type: \(projectType)
        Site context: \(siteContext)
        Climate: \(climate)
        Landmarks: \(landmarks)
        Constraints: \(constraints)
        Program: \(program)

        Return:
        1. 3 concept options.
        2. Massing strategy.
        3. Circulation strategy.
        4. Façade logic.
        5. Structural grid suggestion.
        6. Sustainability ideas.
        7. Risks and assumptions.
        Use concise professional language.
        """
    }

    static func commercialPlanning(
        siteGeometry: String,
        landmarks: String,
        programArea: String,
        constraints: String
    ) -> String {
        """
        Act as a BIM planning assistant for a commercial or airport project.
        Given the site geometry, surrounding landmarks, pedestrian flow, access roads, and program area, propose:
        - zoning strategy,
        - circulation strategy,
        - structural bay logic,
        - services stacking strategy,
        - wayfinding principles,
        - phased delivery plan,
        - coordination risks.
        Site geometry: \(siteGeometry)
        Landmarks: \(landmarks)
        Program area: \(programArea)
        Constraints: \(constraints)
        Return output in bullet points and a JSON summary.
        """
    }

    static func fmHandover(bimSummary: String) -> String {
        """
        Generate a COBie-style asset list from this BIM summary.
        Include: asset name, location, system, manufacturer placeholder, model placeholder, warranty notes, maintenance class, and GUID placeholder.
        Output as CSV-compatible rows.
        BIM summary:
        \(bimSummary)
        """
    }

    static func mixOptimizer(payload: String) -> String {
        """
        You are an expert construction materials AI.
        Given this JSON payload describing target properties, cost and CO2 constraints, and available components:
        \(payload)

        Propose 3 concrete mix designs per m3. Estimate compressive strength, slump, permeability, CO2, and cost. Recommend an MFA-ANN, RF, or SVM-RBF model for refinement. Return one JSON object with `mixes` and `rationale`.
        """
    }

    static func qcReport(project: Project) -> String {
        """
        You are an RPA-style assistant for a construction materials lab.
        Project: \(project.name)
        Material tests: \(project.materialTests.map { "\($0.testType)|\($0.status)|\($0.elementGUID)" }.joined(separator: "; "))

        Detect non-conforming results, group by test type, and generate markdown with Summary, Non-conformances, Detailed Results Table, and Recommendations. Reference BIM element IDs.
        """
    }

    static func designCopilot(project: Project) -> String {
        """
        You are an AI design copilot integrated with BIM.
        Project: \(project.name)
        Climate: \(project.climate)
        Program: \(project.programSummary)
        BIM elements: \(project.elements.map { "\($0.guid)|\($0.elementType)|\($0.material)" }.joined(separator: "; "))

        Suggest 3 envelope and structure strategies. Estimate annual demand, embodied carbon, daylight, and acoustics. Map strategies to BIM element IDs and candidate materials. Return JSON suitable for a BIM view filter.
        """
    }

    static func fabricationPlanner(project: Project) -> String {
        """
        You are a DFMA planner for a modular construction project.
        BIM assemblies: \(project.elements.map { "\($0.guid)|\($0.elementType)|\($0.width)x\($0.height)x\($0.depth)|\($0.material)" }.joined(separator: "; "))
        Capabilities: CNC, additive manufacturing, rebar bending, precast.

        Partition assemblies into manufacturable modules, assign processes, and estimate fabrication time, waste, QA checkpoints, and risks. Return JSON with `modules`, `process_plan`, and `risks`.
        """
    }
}
