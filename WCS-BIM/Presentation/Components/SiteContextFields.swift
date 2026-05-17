import SwiftData
import SwiftUI

struct SiteContextFields: View {
    @Bindable var project: Project

    var body: some View {
        Section("Site context") {
            TextField("Site geometry", text: $project.siteGeometryNotes, axis: .vertical)
            TextField("Zoning", text: $project.zoningNotes, axis: .vertical)
            TextField("Access roads", text: $project.accessRoads, axis: .vertical)
            TextField("Pedestrian flow", text: $project.pedestrianFlow, axis: .vertical)
            TextField("Surrounding context", text: $project.surroundingContext, axis: .vertical)
        }
    }
}
