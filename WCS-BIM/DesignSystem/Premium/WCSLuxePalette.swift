import SwiftUI

/// Chocolate luxe palette with diamond/champagne accents (Display P3–friendly sRGB values).
public enum WCSLuxePalette {
    public static let cocoa = Color(red: 0.22, green: 0.14, blue: 0.10)
    public static let espresso = Color(red: 0.12, green: 0.08, blue: 0.06)
    public static let caramel = Color(red: 0.73, green: 0.53, blue: 0.34)
    public static let diamond = Color(red: 0.97, green: 0.98, blue: 1.00)
    public static let champagne = Color(red: 0.94, green: 0.84, blue: 0.68)
    public static let gold = Color(red: 0.85, green: 0.67, blue: 0.25)

    public static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [espresso, cocoa, Color(red: 0.30, green: 0.18, blue: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
