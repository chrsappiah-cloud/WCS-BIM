import Foundation
import Observation

@MainActor
@Observable
final class RoleDashboardViewModel {
    private(set) var access: APIUserAccess?
    private(set) var dashboard: APIDashboard?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            async let access = api.userAccess()
            async let dashboard = api.dashboard()
            (self.access, self.dashboard) = try await (access, dashboard)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func allows(_ permission: String) -> Bool {
        access?.allows(permission) ?? true
    }
}
