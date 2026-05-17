import Foundation
import SwiftData

struct SiteContextService {
    func syncProjectFields(from project: Project) {
        if project.siteGeometryNotes.isEmpty, !project.programSummary.isEmpty {
            project.siteGeometryNotes = project.programSummary
        }
        if project.zoningNotes.isEmpty, !project.constraintsText.isEmpty {
            project.zoningNotes = project.constraintsText
        }
        if project.surroundingContext.isEmpty, !project.notes.isEmpty {
            project.surroundingContext = project.notes
        }
    }

    func applyToProjectSummary(_ project: Project) {
        if !project.siteGeometryNotes.isEmpty {
            project.programSummary = project.siteGeometryNotes
        }
        if !project.zoningNotes.isEmpty {
            project.constraintsText = project.zoningNotes
        }
    }
}
