import SwiftUI

public struct WCSThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .tint(WCSColor.primary)
            .background(WCSColor.neutralBG.ignoresSafeArea())
            .foregroundStyle(WCSColor.neutralText)
    }
}

public extension View {
    func wcsTheme() -> some View {
        modifier(WCSThemeModifier())
    }
}
