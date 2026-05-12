import SwiftUI

public struct ProfileView: View {
    let displayName: String
    let tier: SubscriptionTier
    let showPaywall: () -> Void

    public init(displayName: String, tier: SubscriptionTier, showPaywall: @escaping () -> Void) {
        self.displayName = displayName
        self.tier = tier
        self.showPaywall = showPaywall
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Theme.Color.sage)
                            .padding(.top, Theme.Spacing.xl)
                        
                        Text(displayName)
                            .font(Theme.Font.display)
                            .foregroundStyle(Theme.Color.textPrimary)

                        TierChipStub(tier: tier)
                    }
                    
                    // Stats
                    HStack(spacing: Theme.Spacing.lg) {
                        StatBox(title: "Scans", value: "14")
                        StatBox(title: "Recipes", value: "3")
                        StatBox(title: "Streak", value: "5 Days")
                    }
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: Theme.Spacing.sm) {
                        if tier == .free {
                            PrimaryButton("Upgrade to Pro") {
                                showPaywall()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    Spacer()
                }
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.Color.textPrimary)
                    }
                }
            }
        }
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Theme.Color.textPrimary)
            Text(title)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Lightweight tier badge
private struct TierChipStub: View {
    let tier: SubscriptionTier

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: Theme.Icon.paywall)
                .font(.caption)
            Text(label)
                .font(Theme.Font.caption.weight(.semibold))
                .textCase(.uppercase)
        }
        .padding(.vertical, Theme.Spacing.xxs)
        .padding(.horizontal, Theme.Spacing.sm)
        .foregroundStyle(foreground)
        .background(
            Capsule()
                .fill(background)
        )
    }

    private var label: String {
        switch tier {
        case .free: return "Free"
        case .premium: return "Pro"
        }
    }

    private var foreground: SwiftUI.Color {
        switch tier {
        case .free: return Theme.Color.textSecondary
        case .premium: return Theme.Color.bone
        }
    }

    private var background: SwiftUI.Color {
        switch tier {
        case .free: return Theme.Color.sage.opacity(0.15)
        case .premium: return Theme.Color.amber
        }
    }
}

#Preview {
    ProfileView(displayName: "Preview User", tier: .free, showPaywall: {})
}
