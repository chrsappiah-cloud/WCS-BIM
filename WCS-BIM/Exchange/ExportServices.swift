import Foundation

typealias COBieExporter = COBieExportService
typealias IFCExporter = IFCExportService

extension COBieExportService {
    func csv(from assets: [AssetRecord]) -> String {
        let project = Project(name: "Export")
        project.assets = assets
        return csv(for: project)
    }
}

extension IFCExportService {
    func placeholderIFC(for projectName: String) -> String {
        stepFile(for: Project(name: projectName))
    }
}
