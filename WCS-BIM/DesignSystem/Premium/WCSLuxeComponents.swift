import SwiftUI

public struct DiamondGlow: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .shadow(color: WCSLuxePalette.diamond.opacity(0.18), radius: 10, x: 0, y: 0)
            .shadow(color: WCSLuxePalette.champagne.opacity(0.18), radius: 18, x: 0, y: 6)
    }
}

public extension View {
    func diamondGlow() -> some View {
        modifier(DiamondGlow())
    }
}

public struct PremiumCard<Content: View>: View {
    private let title: String
    private let subtitle: String
    @ViewBuilder private var content: Content

    public init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(WCSLuxePalette.diamond)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(WCSLuxePalette.champagne.opacity(0.85))
            }
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    WCSLuxePalette.diamond.opacity(0.42),
                                    WCSLuxePalette.gold.opacity(0.35),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .foregroundStyle(WCSLuxePalette.diamond)
        .diamondGlow()
    }
}

public struct DiamondButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(WCSLuxePalette.espresso)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        WCSLuxePalette.diamond,
                        WCSLuxePalette.champagne,
                        WCSLuxePalette.gold.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .diamondGlow()
    }
}

public struct WCSLuxeChromeModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        ZStack {
            WCSLuxePalette.backgroundGradient.ignoresSafeArea()
            content
        }
        .tint(WCSLuxePalette.gold)
        .foregroundStyle(WCSLuxePalette.diamond)
    }
}

public extension View {
    func wcsLuxeChrome() -> some View {
        modifier(WCSLuxeChromeModifier())
    }
}
