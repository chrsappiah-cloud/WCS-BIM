import SwiftUI

public struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(WCSFont.body(15))
                .fontWeight(.medium)
                .foregroundStyle(WCSColor.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous)
                .strokeBorder(WCSColor.primary, lineWidth: 1.5)
        )
        .accessibilityIdentifier("SecondaryButton_\(title)")
        .accessibilityLabel(title)
    }
}
