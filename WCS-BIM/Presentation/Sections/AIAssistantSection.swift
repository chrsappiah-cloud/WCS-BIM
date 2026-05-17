import SwiftUI

struct AIAssistantSection: View {
    @Bindable var project: Project

    var body: some View {
        AIAssistantView(project: project)
    }
}
