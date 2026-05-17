import ARKit
import Combine
import CoreLocation
import RealityKit
import SwiftUI
import UIKit

final class ARPlacementCoordinator: NSObject, ObservableObject, ARSessionDelegate {
    @Published var statusText: String = "Ready"
    var arView: ARView?

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let state = frame.camera.trackingState
        DispatchQueue.main.async { [weak self] in
            self?.statusText = "Tracking: \(state)"
        }
    }

    func placeAnchor(at point: CGPoint) {
        guard let arView else { return }
        let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
        guard let result = results.first else { return }
        let anchor = AnchorEntity(world: result.worldTransform)
        let box = ModelEntity(
            mesh: .generateBox(size: 0.2),
            materials: [SimpleMaterial(color: UIColor.blue, isMetallic: false)]
        )
        anchor.addChild(box)
        arView.scene.addAnchor(anchor)
    }
}

struct InteractiveARView: UIViewRepresentable {
    @ObservedObject var coordinator: ARPlacementCoordinator

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        view.session.delegate = coordinator
        view.session.run(config)
        coordinator.arView = view
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Handler.tap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Handler { Handler(parent: self) }

    final class Handler: NSObject {
        let parent: InteractiveARView
        init(parent: InteractiveARView) { self.parent = parent }

        @objc func tap(_ sender: UITapGestureRecognizer) {
            guard let arView = parent.coordinator.arView else { return }
            let point = sender.location(in: arView)
            parent.coordinator.placeAnchor(at: point)
        }
    }
}
