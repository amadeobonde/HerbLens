import SwiftUI

/// Destructive zone at the bottom of Settings. "Delete account" lives in its own
/// `GlassCard` rendered with `Theme.Color.ember` text — ember is the only place outside
/// scan-warning UIs where we use this hue, so the visual weight is earned. The actual
/// account-delete plumbing isn't on `AuthService` yet (Instance 1/2 to wire), so we
/// gate the destructive call behind a confirmation dialog and a no-op closure injected
/// from `SettingsView`.
struct SettingsAccountSection: View {
    let onDeleteAccount: @Sendable () -> Void

    @State private var showConfirmation: Bool = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Danger zone")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.bottom, Theme.Spacing.xxs)

                Button {
                    showConfirmation = true
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "trash.fill")
                        Text("Delete account")
                            .font(Theme.Font.body.weight(.semibold))
                        Spacer()
                        Image(systemName: Theme.Icon.next)
                            .font(.system(size: 13, weight: .semibold))
                            .opacity(0.6)
                    }
                    .foregroundStyle(Theme.Color.ember)
                    .padding(.vertical, Theme.Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Deletes your scans, vault, and health profile from our servers. This cannot be undone.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary.opacity(0.85))
            }
        }
        .confirmationDialog(
            "Delete your HerbLens account?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive, action: onDeleteAccount)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove your scans, vault, and health profile.")
        }
    }
}
