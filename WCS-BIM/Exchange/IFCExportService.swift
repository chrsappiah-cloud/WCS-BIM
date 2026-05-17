import Foundation

/// Lightweight IFC STEP stub for Revit/IFC workflows — extend with full geometry later.
struct IFCExportService {
    func stepFile(for project: Project) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = [
            "ISO-10303-21;",
            "HEADER;",
            "FILE_DESCRIPTION(('ArchFusion BIM export'),'2;1');",
            "FILE_NAME('\(project.name).ifc','\(timestamp)',('ArchFusion BIM'),(''),'','','');",
            "FILE_SCHEMA(('IFC4'));",
            "ENDSEC;",
            "DATA;"
        ]

        var entityId = 1
        func nextId() -> Int { defer { entityId += 1 }; return entityId }

        let projectId = nextId()
        lines.append("#\(projectId)=IFCPROJECT('\(project.id.uuidString)','$',\(project.name),'',$,$,$,$,$);")

        for element in project.elements {
            let id = nextId()
            let dims = "(\(element.width),\(element.height),\(element.depth))"
            lines.append(
                "#\(id)=IFCBUILDINGELEMENTPROXY('\(element.guid)','$','\(element.name)','\(element.elementType)',#\(projectId),$,$,\(dims),$);"
            )
        }

        lines.append("ENDSEC;")
        lines.append("END-ISO-10303-21;")
        return lines.joined(separator: "\n")
    }
}
