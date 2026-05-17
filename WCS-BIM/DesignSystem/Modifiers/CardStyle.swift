import SwiftUI

public struct CardStyle: ViewModifier {
    public var usePearl: Bool

    public init(usePearl: Bool = false) {
        self.usePearl = usePearl
    }

    public func body(content: Content) -> some View {
        content
            .padding(WCSSpacing.sm)
            .background {
                if usePearl {
                    RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                        .fill(WCSColor.cardBG)
                        .overlay(PearlShimmerOverlay())
                } else {
                    RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                        .fill(WCSColor.cardBG)
                }
            }
            .shadow(
                color: .black.opacity(0.06),
                radius: WCSSpacing.elevationRadius,
                x: 0,
                y: WCSSpacing.elevationY
            )
    }
}

struct PearlShimmerOverlay: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.35),
                WCSColor.secondary.opacity(0.08),
                Color.white.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.softLight)
        .clipShape(RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

public extension View {
    func wcsCard(pearl: Bool = false) -> some View {
        modifier(CardStyle(usePearl: pearl))
    }
}
