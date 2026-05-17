import SwiftUI

public struct StatusChip: View {
    public enum Tone {
        case neutral
        case pending
        case inProgress
        case resolved
        case warning

        var foreground: Color {
            switch self {
            case .neutral: WCSColor.neutralText.opacity(0.85)
            case .pending: WCSColor.highlight
            case .inProgress: WCSColor.primary
            case .resolved: WCSColor.secondary
            case .warning: WCSColor.highlight
            }
        }

        var background: Color {
            foreground.opacity(0.14)
        }
    }

    private let text: String
    private let tone: Tone

    public init(text: String, tone: Tone) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tone.foreground)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(text)
                .font(WCSFont.caption(11))
                .foregroundStyle(tone.foreground)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(tone.background)
        )
        .accessibilityLabel("\(text) status")
        .accessibilityIdentifier("StatusChip_\(text)")
    }
}
