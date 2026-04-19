import SwiftUI

struct FABActionPanel: View {
    let onPhotoScan: () -> Void
    let onBarcodeScan: () -> Void
    let onSearch: () -> Void

    @State private var rowsVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Identify a plant")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                Text("Choose how to look it up")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ActionRow(
                    icon: Theme.Icon.camera,
                    title: "Take a photo",
                    subtitle: "Snap a leaf or bloom",
                    action: onPhotoScan
                )
                .offset(y: rowsVisible ? 0 : 20)
                .opacity(rowsVisible ? 1 : 0)
                .animation(Theme.Motion.bounce.delay(0.0), value: rowsVisible)

                ActionRow(
                    icon: Theme.Icon.barcode,
                    title: "Scan barcode",
                    subtitle: "Read a product label",
                    action: onBarcodeScan
                )
                .offset(y: rowsVisible ? 0 : 20)
                .opacity(rowsVisible ? 1 : 0)
                .animation(Theme.Motion.bounce.delay(0.06), value: rowsVisible)

                ActionRow(
                    icon: Theme.Icon.search,
                    title: "Search by name",
                    subtitle: "Browse our plant database",
                    action: onSearch
                )
                .offset(y: rowsVisible ? 0 : 20)
                .opacity(rowsVisible ? 1 : 0)
                .animation(Theme.Motion.bounce.delay(0.12), value: rowsVisible)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.modal)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(Theme.Shadow.modal)
        .padding(.horizontal, Theme.Spacing.lg)
        .onAppear { rowsVisible = true }
        .onDisappear { rowsVisible = false }
    }
}

private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Color.forest)
                    .frame(width: 44, height: 44)
                    .background(Theme.Color.sage.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Font.callout.weight(.semibold))
                        .foregroundStyle(Theme.Color.textPrimary)

                    Text(subtitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                Spacer()

                Image(systemName: Theme.Icon.next)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Color.sage.opacity(isPressed ? 0.08 : 0))
            )
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(Theme.Motion.snappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ZStack {
        Theme.Color.background.ignoresSafeArea()
        FABActionPanel(
            onPhotoScan: {},
            onBarcodeScan: {},
            onSearch: {}
        )
    }
}
