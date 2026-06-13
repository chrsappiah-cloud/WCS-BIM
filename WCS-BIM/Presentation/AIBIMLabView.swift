import SwiftData
import SwiftUI

struct AIBIMLabView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPillar = Pillar.materials
    @State private var remote = RemoteAIBIMViewModel()
    @State private var roleDashboard = RoleDashboardViewModel()

    enum Pillar: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case materials = "Materials"
        case qa = "QA"
        case design = "Copilot"
        case fabrication = "DFMA"
        case models = "Models"

        var id: String { rawValue }
    }

    private var visiblePillars: [Pillar] {
        Pillar.allCases.filter { pillar in
            switch pillar {
            case .dashboard: true
            case .materials: roleDashboard.allows("predict_materials")
            case .qa: roleDashboard.allows("upload_tests") || roleDashboard.allows("view_reports")
            case .design, .fabrication: roleDashboard.allows("edit_projects")
            case .models: roleDashboard.allows("manage_models")
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local-first workspace").font(.caption.weight(.semibold))
                    Text(remote.errorMessage ?? "Optional Node/Supabase sync is available from Settings.")
                        .font(.caption2)
                    .foregroundStyle(remote.errorMessage == nil ? Color.secondary : Color.orange)
                }
                Spacer()
                if remote.isLoading {
                    ProgressView()
                } else {
                    Button("Sync API") {
                        Task { await remote.refresh(projectID: project.id.uuidString) }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("aiBIM.syncAPI")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Picker("AI BIM module", selection: $selectedPillar) {
                ForEach(visiblePillars) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedPillar {
            case .dashboard:
                RoleDashboardView(viewModel: roleDashboard)
            case .materials:
                MaterialsLabView(project: project)
            case .qa:
                QAAutomationView(project: project)
            case .design:
                DesignCopilotView(project: project)
            case .fabrication:
                FabricationPlannerView(project: project)
            case .models:
                ModelRegistryView()
            }
        }
        .navigationTitle("AI BIM Lab")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await roleDashboard.load()
            if !visiblePillars.contains(selectedPillar) {
                selectedPillar = .dashboard
            }
        }
    }
}

private struct MaterialsLabView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var materialName = "Low-carbon concrete"
    @State private var category = "concrete"
    @State private var targetStrength = 45.0
    @State private var maximumCarbon = 300.0
    @State private var maximumCost = 190.0
    @State private var proposals: [MixDesignProposal] = []
    @State private var cement = 340.0
    @State private var scm = 90.0
    @State private var water = 160.0
    @State private var fineAggregate = 780.0
    @State private var coarseAggregate = 1_050.0
    @State private var admixture = 5.0
    @State private var ageDays = 28.0
    @State private var remote = RemoteAIBIMViewModel()

    private let categories = ["concrete", "geopolymer", "asphalt", "soil", "steel", "FRP", "smart_glass", "smart_brick"]

    var body: some View {
        Form {
            Section("AI-enhanced materials lab") {
                Text("Manage construction materials, predict properties, and optimize mixes under strength, cost, and embodied-carbon constraints.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Material catalog") {
                TextField("Material name", text: $materialName)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ").capitalized).tag($0) }
                }
                Button("Add material locally") {
                    let record = MaterialRecord(
                        name: materialName,
                        category: category,
                        specificationJSON: #"{"source":"AI BIM Materials Lab"}"#
                    )
                    project.materials.append(record)
                    modelContext.insert(record)
                    try? modelContext.save()
                }

                Button("Add material to API") {
                    Task {
                        await remote.createMaterial(
                            projectID: project.id.uuidString,
                            name: materialName,
                            category: category
                        )
                    }
                }
                .disabled(remote.isLoading || materialName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                ForEach(project.materials, id: \.id) { material in
                    LabeledContent(material.name, value: material.category)
                }
            }

            Section("Property prediction") {
                Text("Send a BIM-linked concrete mix to the configured materials model service.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Cement", value: "\(Int(cement)) kg/m3")
                Slider(value: $cement, in: 150...600, step: 5)
                LabeledContent("SCM", value: "\(Int(scm)) kg/m3")
                Slider(value: $scm, in: 0...350, step: 5)
                LabeledContent("Water", value: "\(Int(water)) kg/m3")
                Slider(value: $water, in: 90...280, step: 5)
                LabeledContent("Fine aggregate", value: "\(Int(fineAggregate)) kg/m3")
                Slider(value: $fineAggregate, in: 400...1_200, step: 10)
                LabeledContent("Coarse aggregate", value: "\(Int(coarseAggregate)) kg/m3")
                Slider(value: $coarseAggregate, in: 500...1_400, step: 10)
                Stepper("Admixture: \(Int(admixture)) kg/m3", value: $admixture, in: 0...30, step: 1)
                Stepper("Age: \(Int(ageDays)) days", value: $ageDays, in: 1...365, step: 1)

                Button("Predict material properties") {
                    Task {
                        await remote.predictConcrete(
                            projectID: project.id.uuidString,
                            materialID: project.materials.first?.id.uuidString,
                            inputFeatures: predictionFeatures
                        )
                    }
                }
                .disabled(remote.isLoading)
                .accessibilityIdentifier("aiBIM.predictMaterials")

                if remote.isLoading {
                    ProgressView("Running materials model")
                }
                if let error = remote.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
                if let result = remote.materialPrediction {
                    LabeledContent("Model", value: result.model)
                    LabeledContent("Confidence", value: result.confidence.formatted(.percent.precision(.fractionLength(0))))
                    ForEach(result.prediction.keys.sorted(), id: \.self) { key in
                        LabeledContent(predictionLabel(key), value: predictionValue(key, in: result))
                    }
                    ForEach(result.explanations, id: \.self) { explanation in
                        Text(explanation).font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Save prediction as material test") {
                        savePrediction(result)
                    }
                }
            }

            Section("Mix optimizer") {
                LabeledContent("Target strength", value: "\(Int(targetStrength)) MPa")
                Slider(value: $targetStrength, in: 20...100, step: 5)
                LabeledContent("Maximum CO2", value: "\(Int(maximumCarbon)) kg/m3")
                Slider(value: $maximumCarbon, in: 150...500, step: 10)
                LabeledContent("Maximum cost", value: "$\(Int(maximumCost))/m3")
                Slider(value: $maximumCost, in: 100...350, step: 10)
                Button("Generate 3 optimized mixes") {
                    Task {
                        await remote.optimizeConcrete(
                            targetStrength: targetStrength,
                            maximumCarbon: maximumCarbon,
                            maximumCost: maximumCost
                        )
                        proposals = remote.optimizedMixes.isEmpty
                            ? localOptimizedMixes
                            : remote.optimizedMixes.enumerated().map(remoteProposal)
                    }
                }
                .disabled(remote.isLoading)
                .accessibilityIdentifier("aiBIM.generateMixes")
                if !remote.optimizationRationale.isEmpty {
                    Text(remote.optimizationRationale).font(.caption).foregroundStyle(.secondary)
                } else if remote.errorMessage != nil && !proposals.isEmpty {
                    Text("The model service was unavailable, so constrained local proposals are shown.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            ForEach(proposals) { proposal in
                Section(proposal.name) {
                    LabeledContent("Prediction model", value: proposal.model)
                    LabeledContent("Strength", value: "\(Int(proposal.strengthMPa)) MPa")
                    LabeledContent("Slump", value: "\(Int(proposal.slumpMM)) mm")
                    LabeledContent("Embodied CO2", value: "\(Int(proposal.carbonKG)) kg/m3")
                    LabeledContent("Cost", value: "$\(Int(proposal.costPerM3))/m3")
                    Text(proposal.composition).font(.caption)
                    Button("Save as material test") {
                        let test = MaterialTestRecord(
                            testType: "compressive_strength",
                            inputFeaturesJSON: proposal.composition,
                            predictedValuesJSON: #"{"strength_MPa":\#(proposal.strengthMPa),"slump_mm":\#(proposal.slumpMM),"CO2_kg_m3":\#(proposal.carbonKG)}"#,
                            aiModel: proposal.model,
                            status: "Predicted"
                        )
                        project.materialTests.append(test)
                        modelContext.insert(test)
                        try? modelContext.save()
                    }
                }
            }

            Section("Codex-style endpoint prompt") {
                Text(AIPromptTemplates.mixOptimizer(payload: #"{"target_strength_MPa":45,"max_CO2_kg_m3":300,"max_cost_m3":190}"#))
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
    }

    private var localOptimizedMixes: [MixDesignProposal] {
        AIBIMFourPillarService.optimizeMix(
            targetStrength: targetStrength,
            maximumCarbon: maximumCarbon,
            maximumCost: maximumCost
        )
    }

    private func remoteProposal(offset: Int, mix: APIMixDesign) -> MixDesignProposal {
        let composition = mix.components
            .keys
            .sorted()
            .map { key in "\(predictionLabel(key)): \(Int(mix.components[key] ?? 0)) kg/m3" }
            .joined(separator: ", ")
        return MixDesignProposal(
            name: "ML optimized mix \(offset + 1)",
            model: "Registered strength surrogate",
            strengthMPa: mix.compressiveStrengthMPa,
            slumpMM: mix.slumpMM,
            carbonKG: mix.co2KgPerM3,
            costPerM3: mix.costPerM3,
            composition: composition
        )
    }

    private var predictionFeatures: [String: Double] {
        let binder = max(1, cement + scm)
        return [
            "cement_kg": cement,
            "fly_ash_kg": scm,
            "water_kg": water,
            "fine_aggregate_kg": fineAggregate,
            "coarse_aggregate_kg": coarseAggregate,
            "superplasticizer_kg": admixture,
            "age_days": ageDays,
            "w_b_ratio": water / binder,
            "scm_ratio": scm / binder
        ]
    }

    private func predictionLabel(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func predictionValue(_ key: String, in result: APIMaterialsPredictionResult) -> String {
        guard let value = result.prediction[key] else { return "-" }
        switch key {
        case "compressive_strength_mpa", "tensile_strength_mpa":
            return "\(value.formatted(.number.precision(.fractionLength(1)))) MPa"
        case "permeability":
            return value.formatted(.number.notation(.scientific))
        default:
            return value.formatted(.number.precision(.fractionLength(2)))
        }
    }

    private func savePrediction(_ result: APIMaterialsPredictionResult) {
        let encoder = JSONEncoder()
        let inputs = (try? encoder.encode(predictionFeatures)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let predictions = (try? encoder.encode(result.prediction)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let test = MaterialTestRecord(
            testType: "materials_prediction",
            inputFeaturesJSON: inputs,
            predictedValuesJSON: predictions,
            aiModel: result.model,
            status: "Predicted"
        )
        project.materialTests.append(test)
        modelContext.insert(test)
        try? modelContext.save()
    }
}

private struct QAAutomationView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var testType = "compressive_strength"
    @State private var model = "RF"
    @State private var status = "Conforming"
    @State private var elementGUID = ""
    @State private var report = ""
    @State private var remoteMaterialID = ""
    @State private var remoteElementIDs = ""
    @State private var remoteTestIDs = ""
    @State private var remote = RemoteAIBIMViewModel()

    var body: some View {
        Form {
            Section("Automated testing and QA") {
                Text("Ingest test records, link results to BIM elements, flag non-conformances, and produce an RPA-style report.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("New test record") {
                TextField("Test type", text: $testType)
                Picker("AI model", selection: $model) {
                    ForEach(["MFA-ANN", "RF", "SVM-RBF", "GEP", "ANFIS", "ResNet"], id: \.self) { Text($0).tag($0) }
                }
                Picker("Status", selection: $status) {
                    ForEach(["Pending", "Predicted", "Conforming", "Non-conforming"], id: \.self) { Text($0).tag($0) }
                }
                TextField("Linked BIM element GUID", text: $elementGUID)
                Button("Ingest test") {
                    let test = MaterialTestRecord(
                        testType: testType,
                        inputFeaturesJSON: #"{"ingestion":"manual or lab API"}"#,
                        aiModel: model,
                        status: status,
                        elementGUID: elementGUID
                    )
                    project.materialTests.append(test)
                    modelContext.insert(test)
                    if status == "Non-conforming" {
                        let issue = Issue(
                            title: "Material test non-conformance",
                            details: "\(testType) requires engineering review.",
                            severity: "High",
                            elementGuid: elementGUID
                        )
                        project.issues.append(issue)
                        modelContext.insert(issue)
                    }
                    try? modelContext.save()
                }
            }
            Section("Test register") {
                ForEach(project.materialTests, id: \.id) { test in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(test.testType).font(.headline)
                        Text("\(test.aiModel) | \(test.status)").font(.caption)
                        if !test.elementGUID.isEmpty {
                            Text("BIM: \(test.elementGUID)").font(.caption2.monospaced())
                        }
                    }
                }
            }
            Section("Remote BIM linker") {
                Text("Use API UUIDs from the synced material, BIM element, and test records.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Material UUID", text: $remoteMaterialID)
                    .textInputAutocapitalization(.never)
                TextField("BIM element UUIDs, comma separated", text: $remoteElementIDs)
                    .textInputAutocapitalization(.never)
                TextField("Material test UUIDs, comma separated", text: $remoteTestIDs)
                    .textInputAutocapitalization(.never)
                Button("Link material, tests, and BIM elements") {
                    Task {
                        await remote.linkBIM(
                            projectID: project.id.uuidString,
                            materialID: remoteMaterialID,
                            elementIDs: identifiers(from: remoteElementIDs),
                            testIDs: identifiers(from: remoteTestIDs)
                        )
                    }
                }
                .disabled(remote.isLoading || remoteMaterialID.isEmpty)
                .accessibilityIdentifier("aiBIM.linkRemoteBIM")
                if !remote.linkMessage.isEmpty {
                    Text(remote.linkMessage).font(.caption).foregroundStyle(.green)
                }
                if let error = remote.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
            }
            Section("Remote material-test report") {
                Button("Generate material-test report") {
                    Task {
                        await remote.generateMaterialTestReport(
                            projectID: project.id.uuidString,
                            testIDs: identifiers(from: remoteTestIDs)
                        )
                    }
                }
                .disabled(remote.isLoading)
                .accessibilityIdentifier("aiBIM.generateRemoteMaterialReport")
                if !remote.materialTestReport.isEmpty {
                    Text(remote.materialTestReport).font(.caption.monospaced()).textSelection(.enabled)
                }
            }
            Section("RPA report") {
                Button("Generate QC report") {
                    report = AIBIMFourPillarService.qcReport(tests: project.materialTests, project: project)
                }
                if !report.isEmpty {
                    Text(report).font(.caption.monospaced()).textSelection(.enabled)
                }
            }
        }
    }

    private func identifiers(from value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct DesignCopilotView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var strategies: [DesignStrategyProposal] = []

    var body: some View {
        Form {
            Section("AI-assisted BIM design") {
                Text("Compare envelope and structural strategies while retaining human selection and BIM element traceability.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Generate design alternatives") {
                    strategies = AIBIMFourPillarService.designStrategies(for: project)
                }
                .accessibilityIdentifier("aiBIM.generateStrategies")
            }
            ForEach(strategies) { strategy in
                Section(strategy.name) {
                    Text(strategy.summary)
                    LabeledContent("Energy demand", value: "\(Int(strategy.energyDemand)) kWh/m2.y")
                    LabeledContent("Embodied carbon", value: "\(Int(strategy.embodiedCarbon)) kgCO2e/m2")
                    LabeledContent("Daylight", value: strategy.daylight)
                    LabeledContent("Acoustics", value: strategy.acoustics)
                    Text("Mapped BIM elements: \(strategy.mappedElements)").font(.caption.monospaced())
                    Button("Save design option") {
                        let option = DesignOption(
                            title: strategy.name,
                            summary: strategy.summary,
                            massingNotes: "Energy \(strategy.energyDemand); carbon \(strategy.embodiedCarbon); BIM \(strategy.mappedElements)",
                            score: 1000 - strategy.embodiedCarbon,
                            aiPrompt: AIPromptTemplates.designCopilot(project: project)
                        )
                        project.designOptions.append(option)
                        modelContext.insert(option)
                        try? modelContext.save()
                    }
                }
            }
            Section("Codex-style endpoint prompt") {
                Text(AIPromptTemplates.designCopilot(project: project))
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
    }
}

private struct FabricationPlannerView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var preview: [FabricationModuleProposal] = []

    var body: some View {
        Form {
            Section("DFMA and fabrication planning") {
                Text("Partition BIM assemblies into manufacturable modules, assign production processes, and plan QA checkpoints.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Generate fabrication plan") {
                    preview = AIBIMFourPillarService.fabricationPlan(for: project)
                }
                .accessibilityIdentifier("aiBIM.generateFabrication")
            }
            ForEach(preview) { previewModule in
                Section(previewModule.name) {
                    LabeledContent("Process", value: previewModule.process)
                    LabeledContent("Fabrication time", value: "\(Int(previewModule.fabricationHours)) hours")
                    LabeledContent("Waste", value: String(format: "%.1f%%", previewModule.wastePercent))
                    Text("QA: \(previewModule.qaCheckpoints)")
                    Text("Risk: \(previewModule.risk)").foregroundStyle(.orange)
                    Button("Add module to project plan") {
                        let record = FabricationModuleRecord(
                            name: previewModule.name,
                            process: previewModule.process,
                            elementGUIDs: previewModule.elementGUIDs,
                            fabricationHours: previewModule.fabricationHours,
                            wastePercent: previewModule.wastePercent,
                            qaCheckpoints: previewModule.qaCheckpoints,
                            risk: previewModule.risk
                        )
                        project.fabricationModules.append(record)
                        modelContext.insert(record)
                        try? modelContext.save()
                    }
                }
            }
            Section("Saved fabrication modules") {
                ForEach(project.fabricationModules, id: \.id) { module in
                    LabeledContent(module.name, value: module.process)
                }
            }
            Section("Codex-style endpoint prompt") {
                Text(AIPromptTemplates.fabricationPlanner(project: project))
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
    }
}
