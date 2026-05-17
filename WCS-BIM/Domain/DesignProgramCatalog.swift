import Foundation

/// Building programs and modules from the ArchFusion BIM source pack.
struct DesignProgram: Identifiable, Sendable {
    let id: String
    let name: String
    let projectType: ProjectType
    let programSummary: String
    let designStyle: String
    let constraints: String
}

enum DesignProgramCatalog {
    static let allPrograms: [DesignProgram] = [
        DesignProgram(
            id: "commercial-hub",
            name: "Commercial Hub",
            projectType: .commercial,
            programSummary: "Office and retail podium, 12,000 m² GFA",
            designStyle: "Commercial",
            constraints: "Street frontage activation, 4-level podium"
        ),
        DesignProgram(
            id: "airport-terminal",
            name: "Airport Terminal A",
            projectType: .airport,
            programSummary: "Terminal 40,000 m², 6 gates, landside + airside",
            designStyle: "Airport",
            constraints: "Height limit 45 m, 24 m structural grid"
        ),
        DesignProgram(
            id: "residential-tower",
            name: "Residential Tower",
            projectType: .residential,
            programSummary: "180 units, 32 storeys, amenity deck L4",
            designStyle: "Contemporary",
            constraints: "Setback 6 m, dual-core circulation"
        ),
        DesignProgram(
            id: "mixed-use-waterfront",
            name: "Mixed-Use Waterfront",
            projectType: .mixedUse,
            programSummary: "Retail + hotel + residential, 28,000 m²",
            designStyle: "Parametric",
            constraints: "Flood resilience, public waterfront promenade"
        ),
        DesignProgram(
            id: "institutional-campus",
            name: "Institutional Campus",
            projectType: .institutional,
            programSummary: "Learning hub 8,500 m², labs, library",
            designStyle: "Minimal",
            constraints: "Net-zero ready, modular 7.5 m grid"
        )
    ]
}
