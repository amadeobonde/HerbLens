import SwiftUI

/// Top "Account" card. Avatar (image, initials, or Bamboo mascot fallback) + display
/// name + email + current-tier chip + ghost "Sign out" button. Combining these into
/// one `GlassCard(tone: .subtle)` keeps the most-touched identity affordances inside
/// a single brand-glass surface — separate "Sign out" rows have a long history of
/// being hit by accident.
struct SettingsProfileSection: View {
    let profile: UserProfile?
    let tier: SubscriptionTier
    let onSignOut: @Sendable () -> Void

    @State private var showSignOutConfirmation: Bool = false

    var body: some View {
        GlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .center, spacing: Theme.Spacing.md) {
                    avatar

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile?.displayName ?? "—")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(profile?.email ?? "Sign in to see your email")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }

                    Spacer(minLength: 0)

                    tierChip
                }

                PrimaryButton("Sign out", variant: .ghost) {
                    Task { @MainActor in showSignOutConfirmation = true }
                }
            }
        }
        .confirmationDialog(
            "Sign out of HerbLens?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive, action: onSignOut)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your scans and vault stay in the cloud. You can sign back in anytime.")
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let urlString = profile?.avatarUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    avatarFallback
                @unknown default:
                    avatarFallback
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else if profile?.displayName.isEmpty == false {
            avatarFallback
        } else {
            // No profile yet — fall back to Bamboo so the slot never reads empty.
            MascotBadge(.default, size: 56)
        }
    }

    private var avatarFallback: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.Color.sage.opacity(0.6), Theme.Color.forest.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
            .overlay(
                Text(initial)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
            )
    }

    private var initial: String {
        String(profile?.displayName.prefix(1).uppercased() ?? "·")
    }

    @ViewBuilder
    private var tierChip: some View {
        switch tier {
        case .free:
            Text("Free")
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(Theme.Color.sage)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 4)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Theme.Color.sage, lineWidth: 1)
                )
        case .premium:
            Text("Premium")
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(Theme.Color.bone)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Theme.Color.sage)
                )
        }
    }
}
