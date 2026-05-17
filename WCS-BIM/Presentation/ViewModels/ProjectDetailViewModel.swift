import CoreLocation
import Foundation
import MapKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ProjectDetailViewModel {
    var mapCameraPosition: MapCameraPosition = .automatic
    var arMarkers: [ARPlacedMarker] = []
    var exportMessage: String?
    var showShareSheet = false
    var shareURL: URL?

    private let exportService = ExportService()
    private let exportPipeline = BIMExportPipeline()
    private let designRules = DesignRulesService()

    func configureMap(for project: Project) {
        let center = CLLocationCoordinate2D(latitude: project.siteLatitude, longitude: project.siteLongitude)
        if project.siteLatitude != 0 || project.siteLongitude != 0 {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    func addLandmark(from location: CLLocation, title: String, to project: Project, context: ModelContext) {
        let landmark = Landmark(
            title: title,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            category: "Site Capture"
        )
        project.landmarks.append(landmark)
        context.insert(landmark)
    }

    func addLandmark(at coordinate: CLLocationCoordinate2D, title: String, to project: Project, context: ModelContext) {
        let landmark = Landmark(title: title, latitude: coordinate.latitude, longitude: coordinate.longitude)
        project.landmarks.append(landmark)
        context.insert(landmark)
    }

    func addElement(preset: ParametricPreset, to project: Project, context: ModelContext) {
        let index = project.elements.count + 1
        let name = "\(preset.family.uppercased())-\(String(format: "%03d", index))"
        let element = ParametricLibrary.makeElement(
            from: preset,
            name: name,
            level: 0,
            stage: project.designStage
        )
        project.elements.append(element)
        context.insert(element)
    }

    func validateElement(_ element: BIMElement) -> String? {
        designRules.validateElementName(element.name)
    }

    func export(_ format: String, project: Project, context: ModelContext) {
        let result: ExportResult
        switch format {
        case "IFC": result = exportService.exportIFC(project: project)
        case "COBie": result = exportService.exportCOBie(project: project)
        case "PDF": result = exportService.exportPDF(project: project)
        default: result = exportService.dwgHandoffMetadata(project: project)
        }

        do {
            let url: URL
            if result.format == "PDF" {
                url = try exportPipeline.write(data: result.data, name: result.fileName)
            } else {
                let text = String(data: result.data, encoding: .utf8) ?? ""
                url = try exportPipeline.write(text: text, name: result.fileName)
            }
            shareURL = url
            showShareSheet = true
            let package = ExportPackage(format: result.format, fileName: result.fileName)
            project.exportPackages.append(package)
            context.insert(package)
            exportMessage = "Exported \(result.fileName)"
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
