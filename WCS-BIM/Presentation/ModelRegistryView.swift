import SwiftUI

struct ModelRegistryView: View {
    @State private var viewModel = ModelRegistryViewModel()

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(.orange)
            }

            Section("Retraining") {
                LabeledContent("Status", value: viewModel.retraining?.state.capitalized ?? "Unavailable")
                if let message = viewModel.retraining?.message, !message.isEmpty {
                    Text(message).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .lineLimit(4)
                }
                Button("Run Retraining") {
                    Task { await viewModel.runRetraining() }
                }
                .disabled(viewModel.isLoading || viewModel.retraining?.state == "running")

                Button("Refresh Status") {
                    Task { await viewModel.load() }
                }
                .disabled(viewModel.isLoading)
            }

            if viewModel.items.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Registered Models",
                    systemImage: "brain.head.profile",
                    description: Text("Register a model version to track metrics and activation.")
                )
            }

            ForEach(viewModel.items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(item.modelName) v\(item.version)").font(.headline)
                        Spacer()
                        if item.active {
                            Text("Active").font(.caption.weight(.semibold)).foregroundStyle(.green)
                        } else {
                            Button("Activate") {
                                Task { await viewModel.activate(id: item.id) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    Text(item.task).foregroundStyle(.secondary)
                    if let r2 = item.metrics["r2"] {
                        LabeledContent("R2", value: r2.formatted(.number.precision(.fractionLength(3))))
                            .font(.caption)
                    }
                    if let notes = item.notes {
                        Text(notes).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
        .toolbar {
            Button("Register baseline") {
                Task { await viewModel.createBaseline() }
            }
        }
        .task { await viewModel.load() }
    }
}
