import SwiftData
import SwiftUI

struct FMHandoverSection: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Issues & Clashes") {
                ForEach(project.issues.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { issue in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(issue.title).font(.headline)
                            Spacer()
                            Text(issue.status).font(.caption).padding(4).background(.quaternary, in: Capsule())
                        }
                        if !issue.zone.isEmpty {
                            Text("Zone: \(issue.zone)").font(.caption)
                        }
                        Text(issue.details).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let sorted = project.issues.sorted(by: { $0.createdAt > $1.createdAt })
                    for i in indexSet { modelContext.delete(sorted[i]) }
                }

                Button("Log Issue", systemImage: "exclamationmark.triangle") {
                    let issue = Issue(title: "New Issue", severity: "Medium", zone: "Unassigned")
                    project.issues.append(issue)
                    modelContext.insert(issue)
                }
            }

            Section("Asset Register (COBie)") {
                ForEach(project.assets, id: \.id) { asset in
                    NavigationLink {
                        AssetEditorView(asset: asset)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(asset.assetName)
                            Text("\(asset.system) · \(asset.location)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { modelContext.delete(project.assets[i]) }
                }

                Button("Add Asset", systemImage: "plus") {
                    let asset = AssetRecord(assetName: "Asset \(project.assets.count + 1)")
                    project.assets.append(asset)
                    modelContext.insert(asset)
                }

                Button("Generate Assets from Elements", systemImage: "arrow.triangle.2.circlepath") {
                    for element in project.elements {
                        guard !project.assets.contains(where: { $0.linkedElementGUID == element.guid }) else { continue }
                        let asset = AssetRecord(
                            assetName: element.name,
                            location: "Level \(element.level) / \(element.zone)",
                            system: element.elementType,
                            maintenanceClass: "Routine",
                            linkedElementGUID: element.guid
                        )
                        asset.guid = element.guid
                        project.assets.append(asset)
                        modelContext.insert(asset)
                    }
                }
            }
        }
        .navigationTitle("FM Handover")
    }
}

struct AssetEditorView: View {
    @Bindable var asset: AssetRecord

    var body: some View {
        Form {
            TextField("Asset Name", text: $asset.assetName)
            TextField("Location", text: $asset.location)
            TextField("System", text: $asset.system)
            TextField("Manufacturer", text: $asset.manufacturer)
            TextField("Model", text: $asset.productModel)
            TextField("Warranty", text: $asset.warrantyNotes)
            TextField("Maintenance Class", text: $asset.maintenanceClass)
            Text("GUID: \(asset.guid)").font(.caption.monospaced())
        }
        .navigationTitle(asset.assetName)
    }
}
