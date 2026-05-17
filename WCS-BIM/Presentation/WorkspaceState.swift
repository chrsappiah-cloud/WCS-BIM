import Foundation

@MainActor
@Observable
final class WorkspaceState {
    var selectedProjectID: UUID?

    func select(_ project: Project) {
        selectedProjectID = project.id
    }

    func project(from projects: [Project]) -> Project? {
        guard let selectedProjectID else { return nil }
        return projects.first { $0.id == selectedProjectID }
    }
}
