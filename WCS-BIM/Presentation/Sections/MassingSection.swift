import SwiftData
import SwiftUI

struct MassingSection: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Design options") {
                ForEach(project.designOptions, id: \.id) { option in
                    NavigationLink {
                        DesignOptionEditorView(option: option, project: project)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(option.title).font(.headline)
                                if !option.summary.isEmpty {
                                    Text(option.summary).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if option.isSelected {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { modelContext.delete(project.designOptions[i]) }
                }

                Button("Add design option", systemImage: "plus") {
                    let option = DesignOption(title: "Option \(project.designOptions.count + 1)")
                    project.designOptions.append(option)
                    modelContext.insert(option)
                }
            }

            Section("Massing blocks") {
                let massing = project.elements.filter { $0.family == "Mass" }
                if massing.isEmpty {
                    Text("Add a Mass preset from the Design tab to sketch volume.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(massing, id: \.id) { block in
                        VStack(alignment: .leading) {
                            Text(block.name)
                            Text("\(Int(block.width))×\(Int(block.height))×\(Int(block.depth)) m · L\(block.level)")
                                .font(.caption.monospaced())
                        }
                    }
                }
            }
        }
        .navigationTitle("Massing")
    }
}

struct DesignOptionEditorView: View {
    @Bindable var option: DesignOption
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            TextField("Title", text: $option.title)
            TextField("Summary", text: $option.summary, axis: .vertical)
            TextField("Massing strategy", text: $option.massingNotes, axis: .vertical)
            TextField("AI prompt notes", text: $option.aiPrompt, axis: .vertical)
            Stepper("Score: \(Int(option.score))", value: $option.score, in: 0...100, step: 5)
            Toggle("Selected option", isOn: $option.isSelected)
                .onChange(of: option.isSelected) { _, selected in
                    if selected {
                        for other in project.designOptions where other.id != option.id {
                            other.isSelected = false
                        }
                    }
                }
            Button("Create massing block from option", systemImage: "cube") {
                let block = ParametricLibrary.makeElement(
                    from: ParametricLibrary.presets[0],
                    name: "MASS-\(String(format: "%03d", project.elements.count + 1))",
                    level: 0,
                    stage: project.designStage
                )
                project.elements.append(block)
                modelContext.insert(block)
                option.massingNotes += "\nLinked block: \(block.name)"
            }
        }
        .navigationTitle(option.title)
    }
}
