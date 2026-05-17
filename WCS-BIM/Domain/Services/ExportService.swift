import Foundation

struct ExportResult {
    let fileName: String
    let data: Data
    let format: String
}

struct ExportService {
    private let pipeline = BIMExportPipeline()
    private let reports = ReportBuilder()

    func exportIFC(project: Project) -> ExportResult {
        let content = pipeline.exportIFCPlaceholder(project: project)
        return ExportResult(
            fileName: "\(sanitized(project.name)).ifc",
            data: Data(content.utf8),
            format: "IFC"
        )
    }

    func exportCOBie(project: Project) -> ExportResult {
        let content = pipeline.exportCOBieCSV(project: project)
        return ExportResult(
            fileName: "\(sanitized(project.name))-cobie.csv",
            data: Data(content.utf8),
            format: "COBie"
        )
    }

    func exportPDF(project: Project) -> ExportResult {
        ExportResult(
            fileName: "\(sanitized(project.name))-report.pdf",
            data: reports.pdfData(for: project),
            format: "PDF"
        )
    }

    func dwgHandoffMetadata(project: Project) -> ExportResult {
        let meta: [String: Any] = [
            "project": project.name,
            "guid": project.id.uuidString,
            "site": ["lat": project.siteLatitude, "lon": project.siteLongitude],
            "elements": project.elements.map { [
                "guid": $0.guid,
                "name": $0.name,
                "family": $0.family,
                "size": [$0.width, $0.height, $0.depth]
            ]}
        ]
        let data = (try? JSONSerialization.data(withJSONObject: meta, options: .prettyPrinted)) ?? Data()
        return ExportResult(
            fileName: "\(sanitized(project.name))-revit-handoff.json",
            data: data,
            format: "DWG-Metadata"
        )
    }

    private func sanitized(_ name: String) -> String {
        name.replacingOccurrences(of: " ", with: "-")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}
