import SwiftData
import SwiftUI

struct DesignSection: View {
    @Bindable var project: Project
    @Bindable var viewModel: ProjectDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var designRules = DesignRulesService()

    var body: some View {
        NavigationStack {
            List {
                Section("Parametric Library") {
                    ForEach(ParametricLibrary.presets) { preset in
                        Button {
                            viewModel.addElement(preset: preset, to: project, context: modelContext)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(preset.family).font(.headline)
                                    Text(preset.type).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(preset.defaultWidth))×\(Int(preset.defaultHeight))×\(Int(preset.defaultDepth)) m")
                                    .font(.caption.monospaced())
                            }
                        }
                    }
                }

                Section("BIM Elements (\(project.designStage.displayName))") {
                    ForEach(project.elements, id: \.id) { element in
                        NavigationLink {
                            ElementEditorView(element: element, designRules: designRules)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(element.name)
                                Text("\(element.family) · \(element.elementType) · GUID \(element.guid.prefix(8))…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(project.elements[i]) }
                    }
                }

            }
            .navigationTitle("Design")
        }
    }
}

struct ElementEditorView: View {
    @Bindable var element: BIMElement
    let designRules: DesignRulesService
    @State private var nameWarning: String?

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $element.name)
                    .onChange(of: element.name) { _, new in
                        nameWarning = designRules.validateElementName(new)
                    }
                if let nameWarning {
                    Text(nameWarning).font(.caption).foregroundStyle(.orange)
                }
                Text("GUID: \(element.guid)").font(.caption.monospaced())
            }
            Section("Parameters") {
                TextField("Family", text: $element.family)
                TextField("Type", text: $element.elementType)
                Stepper("Level: \(element.level)", value: $element.level, in: -5...50)
                TextField("Zone", text: $element.zone)
                HStack {
                    ParamField(label: "W", value: $element.width)
                    ParamField(label: "H", value: $element.height)
                    ParamField(label: "D", value: $element.depth)
                }
                TextField("Material", text: $element.material)
            }
            Picker("Stage", selection: $element.designStageRaw) {
                ForEach(DesignStage.allCases) { stage in
                    Text(stage.displayName).tag(stage.rawValue)
                }
            }
        }
        .navigationTitle(element.name)
    }
}

private struct ParamField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack {
            Text(label).font(.caption2)
            TextField(label, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
        }
    }
}
