import Foundation
import SwiftData

/// Installs all design-pack programs with parametric BIM starter elements.
enum DesignProgramInstaller {
    @discardableResult
    static func installAllPrograms(context: ModelContext) -> [Project] {
        var created: [Project] = []
        for program in DesignProgramCatalog.allPrograms {
            if let existing = try? fetchProject(named: program.name, context: context), existing != nil {
                continue
            }
            let project = Project(
                name: program.name,
                notes: "Installed from ArchFusion design pack",
                projectType: program.projectType,
                designStage: .concept,
                programSummary: program.programSummary,
                constraintsText: program.constraints
            )
            context.insert(project)

            for (index, preset) in ParametricLibrary.presets.enumerated() {
                let element = ParametricLibrary.makeElement(
                    from: preset,
                    name: "\(preset.family)-\(index + 1)",
                    level: 0,
                    stage: .concept
                )
                project.elements.append(element)
                context.insert(element)
            }

            let landmark = Landmark(
                title: "\(program.name) Site",
                latitude: -32.9283 + Double(created.count) * 0.001,
                longitude: 151.7817 + Double(created.count) * 0.001,
                category: "Program Anchor",
                note: program.programSummary
            )
            project.landmarks.append(landmark)
            context.insert(landmark)

            created.append(project)
        }
        try? context.save()
        return created
    }

    private static func fetchProject(named name: String, context: ModelContext) throws -> Project? {
        var descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
