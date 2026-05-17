import PDFKit
import UIKit

struct ReportBuilder {
    func summary(for project: Project) -> String {
        let land = project.landmarks.map(\.title).joined(separator: ", ")
        return """
        Project: \(project.name)
        Landmarks: \(land)
        Issues: \(project.issues.count)
        Elements: \(project.elements.count)
        Notes: \(project.notes)
        """
    }

    func pdfData(for project: Project) -> Data {
        pdfData(text: summary(for: project))
    }

    func pdfData(text: String) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "ArchFusion BIM"] as [String: Any]
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        let rendered = renderer.pdfData { ctx in
            ctx.beginPage()
            text.draw(
                in: CGRect(x: 40, y: 40, width: 515, height: 760),
                withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
            )
        }
        if let doc = PDFDocument(data: rendered), doc.pageCount > 0 {
            return doc.dataRepresentation() ?? rendered
        }
        return rendered
    }
}
