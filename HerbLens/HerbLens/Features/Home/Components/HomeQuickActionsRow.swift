import SwiftUI

/// Four-tile quick action row: Scan / Recipes / Vault / Chat. Each tile is an
/// 80×80 `GlassCard` with an SF Symbol from `Theme.Icon` plus a label. Taps fire
/// the matching navigation closure — wiring into actual destinations is deferred
/// to whichever instance owns that tab root (closures are placeholders today).
struct HomeQuickActionsRow: View {
    let onScan: () -> Void
    let onRecipes: () -> Void
    let onVault: () -> Void
    let onChat: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            tile(label: "Scan", systemImage: Theme.Icon.scan, action: onScan)
            tile(label: "Recipes", systemImage: Theme.Icon.recipes, action: onRecipes)
            tile(label: "Vault", systemImage: Theme.Icon.vault, action: onVault)
            tile(label: "Chat", systemImage: Theme.Icon.chat, action: onChat)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func tile(label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassCard(tone: .subtle) {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Theme.Color.forest)
                    Text(label)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 80)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
