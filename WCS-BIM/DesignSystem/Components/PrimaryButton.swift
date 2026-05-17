import SwiftUI

public struct PrimaryButton: View {
    public enum Layout {
        case fullWidth
        case compact
    }

    private let title: String
    private let layout: Layout
    private let isEnabled: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        layout: Layout = .fullWidth,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.layout = layout
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(WCSFont.body(layout == .compact ? 15 : 16))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.vertical, layout == .compact ? 8 : 12)
                .padding(.horizontal, layout == .compact ? 14 : 16)
                .frame(maxWidth: layout == .fullWidth ? .infinity : nil)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                .fill(isEnabled ? WCSColor.primary : WCSColor.neutral4)
        )
        .disabled(!isEnabled)
        .accessibilityIdentifier("PrimaryButton_\(title)")
        .accessibilityLabel(title)
    }
}
