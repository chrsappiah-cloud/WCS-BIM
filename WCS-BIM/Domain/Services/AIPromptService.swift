import Foundation

@MainActor
@Observable
final class AIPromptService {
    var isLoading = false
    var lastError: String?

    private var assistantService: AIAssistantService

    init(apiKey: String?) {
        assistantService = AIAssistantService(apiKey: apiKey ?? "")
    }

    func updateAPIKey(_ key: String?) {
        assistantService = AIAssistantService(apiKey: key ?? "")
    }

    func generate(type: AIPromptType, project: Project) async -> String {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            switch type {
            case .concept:
                return try await assistantService.generateConcepts(
                    projectName: project.name,
                    site: String(format: "%.5f, %.5f", project.siteLatitude, project.siteLongitude),
                    landmarks: project.landmarks.map(\.title),
                    program: project.programSummary.isEmpty ? project.notes : project.programSummary
                )
            case .commercialPlanning, .fmHandover:
                let prompt: String
                switch type {
                case .commercialPlanning:
                    prompt = AIPromptTemplates.commercialPlanning(
                        siteGeometry: String(format: "%.5f, %.5f", project.siteLatitude, project.siteLongitude),
                        landmarks: landmarkSummary(project),
                        programArea: project.programSummary,
                        constraints: project.constraintsText
                    )
                case .fmHandover:
                    let summary = project.elements.map { "\($0.name) | \($0.elementType) | \($0.guid)" }.joined(separator: "\n")
                    prompt = AIPromptTemplates.fmHandover(bimSummary: summary)
                default:
                    prompt = ""
                }
                return try await assistantService.generateCustom(userPrompt: prompt, project: project)
            }
        } catch {
            lastError = error.localizedDescription
            return "AI request failed. Add an API key or check your connection."
        }
    }

    func generateCustom(userPrompt: String, project: Project) async -> String {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            return try await assistantService.generateCustom(userPrompt: userPrompt, project: project)
        } catch {
            lastError = error.localizedDescription
            return "AI request failed. Add an API key or check your connection."
        }
    }
}

private func landmarkSummary(_ project: Project) -> String {
    project.landmarks.map { "\($0.title) (\($0.category))" }.joined(separator: ", ")
}
