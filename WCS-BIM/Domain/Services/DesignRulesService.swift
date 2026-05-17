import Foundation

/// QA/QC and naming rules — AI assists but does not override standards.
struct DesignRulesService {
    func validateElementName(_ name: String) -> String? {
        let pattern = #"^[A-Z]{2,4}-[A-Z0-9]+-[0-9]{3}$"#
        if name.range(of: pattern, options: .regularExpression) == nil {
            return "Use format DISC-TYPE-001 (e.g. WAL-PNL-001)"
        }
        return nil
    }

    func validateGUID(_ guid: String) -> Bool {
        UUID(uuidString: guid) != nil || guid.count >= 8
    }

    func clashSummary(issues: [Issue]) -> String {
        let open = issues.filter { $0.status.lowercased() == "open" }
        if open.isEmpty { return "No open clashes or issues." }
        return open.map { "[\($0.zone)] \($0.title)" }.joined(separator: "\n")
    }
}
