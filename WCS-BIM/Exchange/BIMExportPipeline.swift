import Foundation

struct BIMExportPipeline {
    private let cobie = COBieExportService()
    private let ifc = IFCExportService()

    func exportCOBieCSV(project: Project) -> String {
        cobie.csv(for: project)
    }

    func exportIFCPlaceholder(project: Project) -> String {
        ifc.stepFile(for: project)
    }

    func write(text: String, name: String) throws -> URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = folder.appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func write(data: Data, name: String) throws -> URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = folder.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
