import Foundation
import Observation

@MainActor
@Observable
final class RemoteAIBIMViewModel {
    private(set) var materials: [APIMaterial] = []
    private(set) var tests: [APIMaterialTest] = []
    private(set) var alternatives: [APIDesignAlternative] = []
    private(set) var modules: [APIFabricationModule] = []
    private(set) var remoteQCReport = ""
    private(set) var materialPrediction: APIMaterialsPredictionResult?
    private(set) var linkMessage = ""
    private(set) var optimizedMixes: [APIMixDesign] = []
    private(set) var optimizationRationale = ""
    private(set) var materialTestReport = ""
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func refresh(projectID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            async let materials = api.materials(projectID: projectID)
            async let tests = api.tests(projectID: projectID)
            async let alternatives = api.designAlternatives(projectID: projectID)
            async let modules = api.fabricationModules(projectID: projectID)
            self.materials = try await materials
            self.tests = try await tests
            self.alternatives = try await alternatives
            self.modules = try await modules
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func predictConcrete(projectID: String, materialID: String?, inputFeatures: [String: Double]) async {
        isLoading = true
        errorMessage = nil
        materialPrediction = nil
        defer { isLoading = false }

        do {
            let api = try BIMAPIClient.configured()
            materialPrediction = try await api.predictMaterials(
                APIMaterialsPredictionRequest(
                    projectId: projectID,
                    materialId: materialID,
                    materialType: "concrete",
                    inputFeatures: inputFeatures
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func optimizeConcrete(targetStrength: Double, maximumCarbon: Double, maximumCost: Double) async {
        isLoading = true
        errorMessage = nil
        optimizedMixes = []
        optimizationRationale = ""
        defer { isLoading = false }

        do {
            let api = try BIMAPIClient.configured()
            let result = try await api.optimizeMaterials(
                APIMixOptimizerRequest(
                    targetProperties: ["compressive_strength_mpa": targetStrength],
                    constraints: [
                        "max_co2_kg_per_m3": maximumCarbon,
                        "max_cost_per_m3": maximumCost
                    ],
                    availableComponents: ["cement", "fly_ash", "ggbss", "silica_fume", "water", "aggregates", "superplasticizer"]
                )
            )
            optimizedMixes = result.mixes
            optimizationRationale = result.rationale
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createMaterial(projectID: String, name: String, category: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let api = try BIMAPIClient.configured()
            let material = try await api.createMaterial(
                APIMaterialCreateRequest(
                    projectId: projectID,
                    name: name,
                    category: category,
                    spec: ["source": "AI BIM Materials Lab"]
                )
            )
            materials.insert(material, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func linkBIM(projectID: String, materialID: String, elementIDs: [String], testIDs: [String]) async {
        isLoading = true
        errorMessage = nil
        linkMessage = ""
        defer { isLoading = false }

        do {
            let api = try BIMAPIClient.configured()
            let result = try await api.linkBIM(
                projectID: projectID,
                payload: APIBIMLinkRequest(
                    materialId: materialID,
                    bimElementIds: elementIDs,
                    testIds: testIDs
                )
            )
            linkMessage = "Linked \(result.linkedElements) BIM element(s) and \(result.linkedTests) test(s)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateMaterialTestReport(projectID: String, testIDs: [String]) async {
        isLoading = true
        errorMessage = nil
        materialTestReport = ""
        defer { isLoading = false }

        do {
            let api = try BIMAPIClient.configured()
            let result = try await api.generateMaterialTestReport(
                APIMaterialTestReportRequest(projectId: projectID, testIds: testIDs)
            )
            materialTestReport = result.markdown
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateQCReport(projectID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let api = try BIMAPIClient.configured()
            let result = try await api.generateQCReport(
                APIQCReportRequest(projectId: projectID, testIds: tests.map(\.id))
            )
            remoteQCReport = result.markdown
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
