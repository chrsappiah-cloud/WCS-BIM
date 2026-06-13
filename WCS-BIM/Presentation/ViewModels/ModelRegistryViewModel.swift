import Foundation
import Observation

@MainActor
@Observable
final class ModelRegistryViewModel {
    private(set) var items: [APIModelRecord] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var retraining: APIRetrainStatus?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            items = try await api.models()
            do {
                retraining = try await api.retrainingStatus()
            } catch {
                retraining = nil
            }
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    func createBaseline() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            _ = try await api.createModel(APIModelCreateRequest(
                modelName: "GradientBoostingRegressor",
                version: "1.0.0",
                task: "compressive_strength",
                featureSet: ["cement", "scm", "water", "age", "w_b_ratio", "scm_ratio"],
                metrics: ["r2": 0.74, "mae": 2.48, "rmse": 3.17],
                artifactPath: "models/gbr_v1.joblib",
                active: false,
                notes: "Baseline tabular model for HPC mix prediction"
            ))
            items = try await api.models()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func activate(id: String) async {
        do {
            _ = try await BIMAPIClient.configured().activateModel(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runRetraining() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            _ = try await api.runRetraining()
            retraining = try await api.retrainingStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
