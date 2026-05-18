import SwiftData
import SwiftUI

/// Admin/user panel for Apple sensors, capture APIs, and external AI providers.
struct FieldSystemsView: View {
    @Bindable var hub: APIIntegrationHub
    var project: Project?

    @AppStorage("preferredAIProvider") private var preferredAIProvider = "openai.chat"
    @State private var showCamera = false
    @State private var aiPrompt = "Summarize site capture priorities for BIM coordination."
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Activate sensors") {
                PrimaryButton(hub.motion.isActive ? "Sensors active" : "Activate GPS + Motion", layout: .fullWidth) {
                    if hub.motion.isActive {
                        hub.deactivateFieldSensors()
                    } else {
                        hub.activateFieldSensors()
                    }
                }
                .accessibilityIdentifier("fieldSystems.toggleSensors")

                if let snapshot = hub.lastSensorSnapshot {
                    LabeledContent("GPS") {
                        Text(coordinateLabel(snapshot))
                            .font(.caption.monospaced())
                    }
                    if let accel = snapshot.acceleration {
                        LabeledContent("Motion") {
                            Text(String(format: "a(%.2f, %.2f, %.2f)", accel.0, accel.1, accel.2))
                                .font(.caption.monospaced())
                        }
                    }
                }
            }

            Section("Image capture") {
                PrimaryButton("Open camera", layout: .fullWidth) {
                    showCamera = true
                }
                .accessibilityIdentifier("fieldSystems.openCamera")

                if let capture = hub.lastCapture {
                    Text("OCR: \(capture.ocrText.isEmpty ? "—" : capture.ocrText)")
                        .font(.caption)
                        .lineLimit(4)
                        .accessibilityIdentifier("fieldSystems.lastOCR")
                }
            }

            Section("AI generation") {
                Picker("Provider", selection: $preferredAIProvider) {
                    ForEach(APIProviderCatalog.externalAI, id: \.id) { entry in
                        Text(entry.name).tag(entry.id)
                    }
                }
                .accessibilityIdentifier("fieldSystems.aiProvider")

                TextField("Prompt", text: $aiPrompt, axis: .vertical)
                    .accessibilityIdentifier("fieldSystems.aiPrompt")

                PrimaryButton("Generate", layout: .fullWidth, isEnabled: !hub.isProcessing) {
                    Task { await hub.generateAI(prompt: aiPrompt) }
                }
                .accessibilityIdentifier("fieldSystems.aiGenerate")

                if !hub.lastAIMessage.isEmpty {
                    Text(hub.lastAIMessage)
                        .font(.caption)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("fieldSystems.aiResult")
                }
            }

            Section("Integrated APIs") {
                ForEach(APIProviderCatalog.Category.allCases, id: \.self) { category in
                    DisclosureGroup(category.rawValue) {
                        ForEach(APIProviderCatalog.entries(in: category)) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name).font(WCSFont.label())
                                Text(entry.framework).font(WCSFont.caption()).foregroundStyle(.secondary)
                                Text(entry.description).font(WCSFont.caption())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Field Systems")
        .accessibilityIdentifier("fieldSystems.screen")
        .onAppear { hub.activateFieldSensors() }
        .onDisappear { hub.deactivateFieldSensors() }
        .sheet(isPresented: $showCamera) {
            AppleCameraCaptureView(
                onImage: { image in
                    showCamera = false
                    Task {
                        let media = await hub.processCapturedImage(
                            image,
                            projectID: project?.id ?? UUID()
                        )
                        persistObservation(from: media)
                    }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
    }

    private func coordinateLabel(_ snapshot: SensorSnapshot) -> String {
        guard let lat = snapshot.latitude, let lon = snapshot.longitude else { return "—" }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    private func persistObservation(from media: CapturedSiteMedia) {
        guard let project else { return }
        let observation = SiteObservation(
            title: "Field capture",
            note: media.ocrText.isEmpty ? "Camera capture" : media.ocrText,
            latitude: media.latitude,
            longitude: media.longitude,
            photoPath: media.savedPath
        )
        project.observations.append(observation)
        modelContext.insert(observation)
    }
}
