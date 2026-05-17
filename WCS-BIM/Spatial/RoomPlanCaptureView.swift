import SwiftUI

/// RoomPlan integration placeholder — wire `RoomCaptureView` when targeting physical devices.
struct RoomPlanCapturePlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "RoomPlan",
            systemImage: "view.3d",
            description: Text("Interior scanning requires a physical iOS device with RoomPlan. Connect an iPad or iPhone to capture rooms.")
        )
    }
}
