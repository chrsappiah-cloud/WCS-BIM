import SwiftData
import SwiftUI

struct AIAssistantView: View {
    var fixedProject: Project?

    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("openAIApiKey") private var apiKey = ""
    @State private var prompt = ""
    @State private var response = ""
    @State private var aiService = AIPromptService(apiKey: nil)
    @State private var selectedProjectID: UUID?

    init(project: Project? = nil) {
        self.fixedProject = project
    }

    private var activeProject: Project? {
        if let fixedProject { return fixedProject }
        guard let selectedProjectID else { return projects.first }
        return projects.first { $0.id == selectedProjectID } ?? projects.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if projects.isEmpty {
                    Text("Create a project first to save AI interactions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if fixedProject == nil, projects.count > 1 {
                    Picker("Project", selection: $selectedProjectID) {
                        ForEach(projects, id: \.id) { p in
                            Text(p.name).tag(Optional(p.id))
                        }
                    }
                }

                TextField(
                    "Ask for massing, zoning, circulation, sustainability...",
                    text: $prompt,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)

                Button("Generate") {
                    Task { await generate() }
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isLoading)

                if aiService.isLoading { ProgressView() }

                ScrollView {
                    Text(response)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("AI Assistant")
            .onAppear {
                migrateLegacyAPIKey()
                syncAPIKey()
                if selectedProjectID == nil {
                    selectedProjectID = fixedProject?.id ?? projects.first?.id
                }
            }
            .onChange(of: apiKey) { _, _ in syncAPIKey() }
        }
    }

    private func migrateLegacyAPIKey() {
        if apiKey.isEmpty, let legacy = UserDefaults.standard.string(forKey: "openai_api_key"), !legacy.isEmpty {
            apiKey = legacy
        }
    }

    private func syncAPIKey() {
        aiService.updateAPIKey(apiKey.isEmpty ? nil : apiKey)
    }

    private func generate() async {
        guard let project = activeProject else {
            response = "Create a project in the Projects tab first."
            return
        }
        syncAPIKey()
        let userPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = await aiService.generateCustom(userPrompt: userPrompt, project: project)
        response = result

        let interaction = AIInteraction(prompt: userPrompt, response: result)
        project.aiInteractions.append(interaction)
        modelContext.insert(interaction)
    }
}
