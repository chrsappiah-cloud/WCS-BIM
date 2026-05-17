import ARKit
import RealityKit
import SwiftUI
import simd

struct ARPlacedMarker: Identifiable {
    let id = UUID()
    let title: String
    var transform: simd_float4x4
}

struct SiteARView: UIViewRepresentable {
    @Binding var markers: [ARPlacedMarker]
    var onTapPlace: ((simd_float4x4) -> Void)?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.syncMarkers(markers)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(markers: $markers, onTapPlace: onTapPlace)
    }

    final class Coordinator: NSObject {
        @Binding var markers: [ARPlacedMarker]
        var onTapPlace: ((simd_float4x4) -> Void)?
        weak var arView: ARView?

        init(markers: Binding<[ARPlacedMarker]>, onTapPlace: ((simd_float4x4) -> Void)?) {
            _markers = markers
            self.onTapPlace = onTapPlace
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let point = gesture.location(in: arView)
            let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
            guard let hit = results.first else { return }

            let anchor = AnchorEntity(world: hit.worldTransform)
            let mesh = MeshResource.generateBox(size: 0.15)
            let material = SimpleMaterial(color: UIColor.systemOrange, isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            onTapPlace?(hit.worldTransform)
        }

        func syncMarkers(_ markers: [ARPlacedMarker]) {
            // Visual markers are added on tap; binding tracks metadata for export.
        }
    }
}

extension simd_float4x4 {
    var encodedData: Data? {
        withUnsafeBytes(of: self) { Data($0) }
    }

    init?(data: Data) {
        guard data.count == MemoryLayout<simd_float4x4>.size else { return nil }
        self = data.withUnsafeBytes { $0.load(as: simd_float4x4.self) }
    }
}
