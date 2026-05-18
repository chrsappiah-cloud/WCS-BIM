import SwiftUI

#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton("New Project") {}
        SecondaryButton("Cancel") {}
    }
    .padding()
    .wcsTheme()
}

#Preview("Card") {
    CardView(
        title: "Terminal A",
        subtitle: "Commercial · Concept",
        systemImage: "building.2",
        chips: ["IFC", "Site", "Open"],
        pearl: true
    ) {
        Text("3 issues · Synced")
            .font(WCSFont.caption())
            .foregroundStyle(WCSColor.neutralText.opacity(0.7))
    }
    .padding()
    .wcsTheme()
}

#Preview("Inspector") {
    struct Host: View {
        @State private var show = true
        @State private var params = [
            InspectorParam(key: "Name", value: "Wall-01"),
            InspectorParam(key: "GUID", value: "abc-123"),
            InspectorParam(key: "Width", value: "200")
        ]
        var body: some View {
            Color.clear
                .sheet(isPresented: $show) {
                    InspectorSheet(isPresented: $show, params: $params) { _ in }
                        .presentationDetents([.medium, .large])
                }
                .onAppear { show = true }
        }
    }
    return Host().wcsTheme()
}

#Preview("Luxe Home") {
    WCSLuxeHomeView()
}
