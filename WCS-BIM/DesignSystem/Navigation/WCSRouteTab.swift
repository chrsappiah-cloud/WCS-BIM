import SwiftUI

/// Primary app routes for the BIM tab shell (stable IDs for UI tests).
public struct WCSRouteTab: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let accessibilityIdentifier: String?

    public init(
        id: String,
        title: String,
        systemImage: String,
        accessibilityIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    /// Design-kit initializer (`title` + SF Symbol only).
    public init(title: String, systemImage: String) {
        let slug = title.lowercased().replacingOccurrences(of: " ", with: "-")
        self.init(id: slug, title: title, systemImage: systemImage)
    }
}

public extension WCSRouteTab {
    /// Five-tab learning shell (matches generated `WCSRouteTab.all`).
    static let all: [WCSRouteTab] = [
        WCSRouteTab(title: "Home", systemImage: "house.fill"),
        WCSRouteTab(title: "Learn", systemImage: "book.fill"),
        WCSRouteTab(title: "Tasks", systemImage: "checklist"),
        WCSRouteTab(title: "Reports", systemImage: "chart.bar.fill"),
        WCSRouteTab(title: "Profile", systemImage: "person.crop.circle.fill")
    ]

    /// Core BIM tab bar. Export and Settings live in the explicit More route
    /// so iPhone navigation does not depend on UIKit's automatic overflow.
    static let bimWorkflow: [WCSRouteTab] = [
        WCSRouteTab(
            id: "projects",
            title: "Projects",
            systemImage: "building.2",
            accessibilityIdentifier: "tab.projects"
        ),
        WCSRouteTab(
            id: "site",
            title: "Site",
            systemImage: "map",
            accessibilityIdentifier: "tab.site"
        ),
        WCSRouteTab(
            id: "ar",
            title: "AR",
            systemImage: "viewfinder",
            accessibilityIdentifier: "tab.ar"
        ),
        WCSRouteTab(
            id: "export",
            title: "Export",
            systemImage: "square.and.arrow.up",
            accessibilityIdentifier: "tab.export"
        ),
        WCSRouteTab(
            id: "more",
            title: "More",
            systemImage: "ellipsis",
            accessibilityIdentifier: "tab.more"
        )
    ]

    /// Alias for `all` (five-tab learning shell).
    static var learningShell: [WCSRouteTab] { all }
}
