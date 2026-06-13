import SwiftUI

// MARK: - Navigation rows & headers

public struct WCSNavArrowButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 22)
                Text(title)
                    .font(WCSFont.label())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(WCSColor.neutralText)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

public struct WCSBackButton: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .font(WCSFont.label())
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go back")
        .accessibilityIdentifier("nav.back")
    }
}

public struct WCSPrimaryActionButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
            }
            .font(.headline.weight(.semibold))
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(WCSColor.primary)
        .controlSize(.large)
        .accessibilityHint("Opens the next step")
    }
}

public struct WCSSmallIconButton: View {
    private let systemImage: String
    private let label: String
    private let action: () -> Void

    public init(systemImage: String, label: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
    }
}

public struct WCSInlineLinkRow: View {
    private let title: String
    private let subtitle: String
    private let actionTitle: String
    private let action: () -> Void

    public init(
        title: String,
        subtitle: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(WCSFont.label())
                Text(subtitle)
                    .font(WCSFont.caption())
                    .foregroundStyle(WCSColor.neutralText.opacity(0.75))
            }
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .tint(WCSColor.primary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: WCSSpacing.cornerRadius, style: .continuous))
    }
}

public struct WCSSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(WCSFont.title(20))
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(WCSFont.caption().weight(.semibold))
                    .tint(WCSColor.primary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Grids & chrome

public struct WCSQuickNavGrid: View {
    public struct Item: Identifiable {
        public let id = UUID()
        public let title: String
        public let systemImage: String
        public let action: () -> Void

        public init(title: String, systemImage: String, action: @escaping () -> Void) {
            self.title = title
            self.systemImage = systemImage
            self.action = action
        }
    }

    private let items: [Item]

    public init(items: [Item]) {
        self.items = items
    }

    public init(
        items tuples: [(title: String, systemImage: String, action: () -> Void)]
    ) {
        self.items = tuples.map { Item(title: $0.title, systemImage: $0.systemImage, action: $0.action) }
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 10) {
                        Image(systemName: item.systemImage)
                            .font(.title3)
                        Text(item.title)
                            .font(WCSFont.caption().weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
    }
}

public struct WCSRoutePill: View {
    private let title: String
    private let selected: Bool
    private let action: () -> Void

    public init(title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(WCSFont.caption().weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? WCSColor.primary : WCSColor.neutral3)
                .foregroundStyle(selected ? Color.white : WCSColor.neutralText)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

public struct WCSConnectivityBar: View {
    private let left: String
    private let right: String

    public init(left: String, right: String) {
        self.left = left
        self.right = right
    }

    public var body: some View {
        HStack(spacing: 10) {
            Text(left)
            Image(systemName: "arrow.right")
            Text(right)
            Spacer()
        }
        .font(WCSFont.caption().weight(.semibold))
        .foregroundStyle(WCSColor.neutralText.opacity(0.7))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Showcase

/// Design-system gallery for navigation primitives.
public struct WCSNavigationShowcaseView: View {
    @State private var pillIndex = 0
    private let pills = ["Projects", "Site", "AR", "AI"]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WCSConnectivityBar(left: "Projects", right: "Site capture")

                WCSSectionHeader(title: "Quick access", actionTitle: "Edit", action: {})

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(pills.enumerated()), id: \.offset) { index, title in
                            WCSRoutePill(title: title, selected: pillIndex == index) {
                                pillIndex = index
                            }
                        }
                    }
                }

                WCSQuickNavGrid(items: [
                    WCSQuickNavGrid.Item(title: "Projects", systemImage: "building.2", action: {}),
                    WCSQuickNavGrid.Item(title: "Site", systemImage: "map", action: {}),
                    WCSQuickNavGrid.Item(title: "Export", systemImage: "square.and.arrow.up", action: {}),
                    WCSQuickNavGrid.Item(title: "Settings", systemImage: "gearshape", action: {})
                ])

                WCSNavArrowButton(title: "Open Field Systems", systemImage: "antenna.radiowaves.left.and.right", action: {})
                WCSInlineLinkRow(
                    title: "Continue setup",
                    subtitle: "Finish API keys and TestFlight access",
                    actionTitle: "Continue",
                    action: {}
                )
                WCSPrimaryActionButton(title: "Start coordination", systemImage: "play.fill", action: {})
            }
            .padding(20)
        }
        .navigationTitle("Navigation")
        .accessibilityIdentifier("nav.showcase.screen")
    }
}

#Preview("Navigation components") {
    NavigationStack {
        WCSNavigationShowcaseView()
    }
    .wcsTheme()
}

#Preview("Design kit") {
    VStack(spacing: 16) {
        WCSSectionHeader(title: "Quick access", actionTitle: "Edit", action: {})
        WCSQuickNavGrid(items: [
            ("Start", "play.fill", {}),
            ("Review", "eye.fill", {}),
            ("Reports", "chart.bar.fill", {}),
            ("Help", "questionmark.circle.fill", {})
        ])
        WCSNavArrowButton(title: "Open dashboard", systemImage: "house.fill", action: {})
        WCSInlineLinkRow(
            title: "Continue setup",
            subtitle: "Finish your profile and permissions",
            actionTitle: "Continue",
            action: {}
        )
        WCSConnectivityBar(left: "Home", right: "Task details")
    }
    .padding()
    .wcsTheme()
}
