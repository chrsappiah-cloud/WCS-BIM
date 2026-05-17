import Foundation

enum AIPromptType: String, CaseIterable, Identifiable {
    case concept
    case commercialPlanning
    case fmHandover

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concept: "Concept Design"
        case .commercialPlanning: "Commercial / Airport"
        case .fmHandover: "FM Handover (COBie)"
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
}
