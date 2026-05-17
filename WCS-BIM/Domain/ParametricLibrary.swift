import Foundation

struct ParametricPreset: Identifiable {
    let id = UUID()
    let family: String
    let type: String
    let defaultWidth: Double
    let defaultHeight: Double
    let defaultDepth: Double
    let material: String
}

enum ParametricLibrary {
    static let presets: [ParametricPreset] = [
        ParametricPreset(family: "Mass", type: "MassingBlock", defaultWidth: 12, defaultHeight: 8, defaultDepth: 12, material: "Concept"),
        ParametricPreset(family: "Wall", type: "Basic Wall", defaultWidth: 0.2, defaultHeight: 3, defaultDepth: 6, material: "Masonry"),
        ParametricPreset(family: "Slab", type: "Floor Slab", defaultWidth: 10, defaultHeight: 0.25, defaultDepth: 10, material: "Concrete"),
        ParametricPreset(family: "Column", type: "Structural Column", defaultWidth: 0.4, defaultHeight: 3.5, defaultDepth: 0.4, material: "Steel"),
        ParametricPreset(family: "Curtain", type: "Curtain Wall", defaultWidth: 1.5, defaultHeight: 3, defaultDepth: 0.1, material: "Glazing")
    ]

    static func makeElement(from preset: ParametricPreset, name: String, level: Int, stage: DesignStage) -> BIMElement {
        BIMElement(
            name: name,
            elementType: preset.type,
            width: preset.defaultWidth,
            height: preset.defaultHeight,
            depth: preset.defaultDepth,
            material: preset.material,
            level: level,
            family: preset.family,
            designStage: stage
        )
    }
}
