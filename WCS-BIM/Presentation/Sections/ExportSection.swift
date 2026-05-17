import SwiftData
import SwiftUI

struct ExportSection: View {
    @Bindable var project: Project
    @Bindable var viewModel: ProjectDetailViewModel
    @Environment(\.modelContext) private var modelContext

    private let formats = ["IFC", "COBie", "PDF", "Revit"]

    var body: some View {
        List {
            Section("Deliverables") {
                ForEach(formats, id: \.self) { format in
                    Button {
                        let key = format == "Revit" ? "DWG" : format
                        viewModel.export(key, project: project, context: modelContext)
                    } label: {
                        Label(formatLabel(format), systemImage: icon(for: format))
                    }
                }
            }

            if let message = viewModel.exportMessage {
                Section {
                    Text(message).font(.caption)
                }
            }

            Section("Export History") {
                ForEach(project.exportPackages.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { pkg in
                    HStack {
                        Text(pkg.format)
                        Spacer()
                        Text(pkg.fileName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Linked GUIDs") {
                Text("All exports preserve element GUIDs for Revit/IFC/COBie continuity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Export")
    }

    private func formatLabel(_ format: String) -> String {
        switch format {
        case "IFC": "IFC STEP"
        case "COBie": "COBie CSV"
        case "PDF": "PDF Report"
        case "Revit": "Revit / DWG Handoff JSON"
        default: format
        }
    }

    private func icon(for format: String) -> String {
        switch format {
        case "IFC": "doc.text"
        case "COBie": "tablecells"
        case "PDF": "doc.richtext"
        default: "arrow.triangle.branch"
        }
    }
}
