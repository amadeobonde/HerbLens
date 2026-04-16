import SwiftUI

/// Section header with a bold title plus an optional trailing accessory (link button,
/// icon, etc.). Use the `EmptyView` default when no accessory is needed.
public struct SectionHeader<Accessory: View>: View {
    private let title: String
    private let accessory: Accessory

    // Note: not `nonisolated` because `Accessory` (an arbitrary SwiftUI `View`) isn't
    // required to be `Sendable`. Construct on the main actor like every other SwiftUI view.
    public init(_ title: String, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.title = title
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer(minLength: Theme.Spacing.sm)
            accessory
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
        SectionHeader("Featured")
        SectionHeader("Recent scans") {
            Button("See all") {}
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.sage)
        }
        SectionHeader("Saved") {
            Image(systemName: Theme.Icon.more)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }
    .padding(.vertical, Theme.Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Theme.Color.background)
}
