import SwiftUI

/// WCS design tokens — Display P3 asset catalog (`DesignSystem/Colors.xcassets`).
public enum WCSColor {
    public static let primary = Color("WCSPrimary", bundle: .main)
    public static let secondary = Color("WCSSecondary", bundle: .main)
    public static let highlight = Color("WCSHighlight", bundle: .main)
    public static let neutralBG = Color("WCSNeutralBG", bundle: .main)
    public static let neutralText = Color("WCSNeutralText", bundle: .main)
    public static let cardBG = Color("WCSCardBG", bundle: .main)
    public static let separator = Color("WCSSeparator", bundle: .main)
    public static let success = Color("WCSSuccess", bundle: .main)
    public static let error = Color("WCSError", bundle: .main)

    /// Cool slate steps (programmatic neutrals for chips / subtle fills).
    public static let neutral2 = Color(white: 0.94)
    public static let neutral3 = Color(white: 0.88)
    public static let neutral4 = Color(white: 0.72)
    public static let neutral5 = Color(white: 0.45)
}
