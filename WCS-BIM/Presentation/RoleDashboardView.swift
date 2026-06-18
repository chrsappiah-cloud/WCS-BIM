import SwiftUI

struct RoleDashboardView: View {
    let viewModel: RoleDashboardViewModel

    var body: some View {
        Form {
            Section("Access") {
                LabeledContent("Role", value: viewModel.dashboard?.role.replacingOccurrences(of: "_", with: " ").capitalized ?? "Local")
                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
            }

            if let counts = viewModel.dashboard?.counts {
                Section("Organization health") {
                    metric("Projects", counts.projects, "building.2")
                    metric("Materials", counts.materials, "cube.box")
                    metric("Tests", counts.tests, "checkmark.seal")
                    metric("Reports", counts.reports, "doc.text")
                    metric("Active models", counts.activeModels, "brain.head.profile")
                }
            }

            Section("Permissions") {
                ForEach(viewModel.access?.permissions ?? [], id: \.self) { permission in
                    Label(
                        permission.replacingOccurrences(of: "_", with: " ").capitalized,
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                }
            }
        }
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
    }

    private func metric(_ title: String, _ value: Int, _ icon: String) -> some View {
        LabeledContent {
            Text(value.formatted()).font(.headline)
        } label: {
            Label(title, systemImage: icon)
        }
    }
}
