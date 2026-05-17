import PDFKit
import UIKit

struct PDFReportService {
    func makeProjectReport(project: Project) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let rendered = renderer.pdfData { context in
            context.beginPage()
            drawTitle("ArchFusion BIM — \(project.name)", at: 40, y: 40)

            var y: CGFloat = 90
            let rows: [(String, String)] = [
                ("Stage", project.designStage.displayName),
                ("Type", project.projectType.displayName),
                ("Site", String(format: "%.5f, %.5f", project.siteLatitude, project.siteLongitude)),
                ("Landmarks", "\(project.landmarks.count)"),
                ("Elements", "\(project.elements.count)"),
                ("Design options", "\(project.designOptions.count)"),
                ("Issues", "\(project.issues.count)"),
                ("Assets", "\(project.assets.count)")
            ]
            for (label, value) in rows {
                drawBody("\(label): \(value)", at: 40, y: y)
                y += 22
            }

            if !project.zoningNotes.isEmpty {
                y += 8
                drawBody("Zoning: \(project.zoningNotes)", at: 40, y: y)
            }

            if !project.notes.isEmpty {
                y += 30
                drawBody("Notes: \(project.notes)", at: 40, y: y)
            }
        }

        if let doc = PDFDocument(data: rendered), doc.pageCount > 0 {
            return doc.dataRepresentation() ?? rendered
        }
        return rendered
    }

    private func drawTitle(_ text: String, at x: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22)]
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }

    private func drawBody(_ text: String, at x: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }
}
