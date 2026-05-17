import Foundation

struct COBieExportService {
    func csv(for project: Project) -> String {
        var rows = ["AssetTag,Location,System,Manufacturer,Model,WarrantyEnd,MaintenanceClass,GUID"]
        for asset in project.assets {
            let warrantyEnd = asset.warrantyEnd.map {
                $0.formatted(date: .numeric, time: .omitted)
            } ?? ""
            rows.append([
                escape(asset.assetTag),
                escape(asset.location),
                escape(asset.system),
                escape(asset.manufacturer),
                escape(asset.productModel),
                escape(warrantyEnd.isEmpty ? asset.warrantyNotes : warrantyEnd),
                escape(asset.maintenanceClass),
                escape(asset.guid)
            ].joined(separator: ","))
        }
        if project.assets.isEmpty {
            for element in project.elements where project.designStage == .record || !project.elements.isEmpty {
                rows.append([
                    escape(element.name),
                    escape("Level \(element.level) / \(element.zone)"),
                    escape(element.elementType),
                    escape("TBD"),
                    escape(element.family),
                    escape(""),
                    escape("Routine"),
                    escape(element.guid)
                ].joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    private func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
