import Foundation

actor AIAssistantService {
    private let client: OpenAIClient

    init(apiKey: String) {
        self.client = OpenAIClient(apiKey: apiKey)
    }

    func generateConcepts(
        projectName: String,
        site: String,
        landmarks: [String],
        program: String
    ) async throws -> String {
        let prompt = """
        You are an architectural BIM assistant.
        Project: \(projectName)
        Site: \(site)
        Landmarks: \(landmarks.joined(separator: "; "))
        Program: \(program)
        Return 3 concept options, zoning, circulation, structural grid, façade strategy, sustainability strategy, construction risks, and FM handover notes.
        """
        return try await client.sendPrompt(prompt)
    }

    func generateCustom(userPrompt: String, project: Project) async throws -> String {
        let prompt = """
        You are an architectural BIM assistant.
        Project: \(project.name)
        Site: \(project.siteLatitude), \(project.siteLongitude)
        Landmarks: \(project.landmarks.map(\.title).joined(separator: "; "))
        Program: \(project.programSummary)

        \(userPrompt)
        """
        return try await client.sendPrompt(prompt)
    }
}
