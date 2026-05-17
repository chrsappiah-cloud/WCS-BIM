import SwiftUI

public struct CardView<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String?
    private let pearl: Bool
    private let chips: [String]
    @ViewBuilder private var content: () -> Content

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        chips: [String] = [],
        pearl: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.chips = chips
        self.pearl = pearl
        self.content = content
    }
}

public extension CardView where Content == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        chips: [String] = [],
        pearl: Bool = false
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            chips: chips,
            pearl: pearl
        ) {
            EmptyView()
        }
    }
}

extension CardView {

    public var body: some View {
        VStack(alignment: .leading, spacing: WCSSpacing.xs) {
            HStack(alignment: .top, spacing: WCSSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(WCSColor.primary)
                        .frame(width: 36, height: 36)
                        .background(WCSColor.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(WCSFont.title(16))
                        .foregroundStyle(WCSColor.neutralText)
                    if let subtitle {
                        Text(subtitle)
                            .font(WCSFont.caption())
                            .foregroundStyle(WCSColor.neutralText.opacity(0.72))
                    }
                }
                Spacer(minLength: 0)
            }

            if !chips.isEmpty {
                HStack(spacing: WCSSpacing.xxs) {
                    ForEach(chips.prefix(3), id: \.self) { chip in
                        StatusChip(text: chip, tone: .neutral)
                    }
                }
            }

            content()
        }
        .wcsCard(pearl: pearl)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("CardView_\(title)")
    }
}
