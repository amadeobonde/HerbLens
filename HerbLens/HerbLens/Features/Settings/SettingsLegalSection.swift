import SwiftUI

nonisolated enum LegalDocumentKind: String, Hashable, Sendable, CaseIterable {
    case privacy
    case terms
    case licenses

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Service"
        case .licenses: return "Open-source Licenses"
        }
    }

    /// Placeholder copy until legal sign-off lands. The banner on `LegalDocumentView`
    /// surfaces this explicitly so a reviewer never ships these to TestFlight thinking
    /// they are final.
    var placeholderBody: String {
        switch self {
        case .privacy:
            return """
            HerbLens collects the minimum data required to identify plants, score them against your goals, and show you recipes. We do not sell personal data. Full policy pending legal review.

            What we collect:
            • Account email (required for sign-in)
            • Health goals, allergies, medications, conditions (used to compute health scores)
            • Photos of plants you scan (stored in your Supabase bucket; you can delete any scan from the Vault)
            • Subscription status (from RevenueCat)

            We never share identifiable data with third parties. Anonymized, aggregate analytics via PostHog support product decisions and are opt-out in a future build.

            Contact: privacy@herblens.app
            """
        case .terms:
            return """
            By using HerbLens you agree to the following terms. Full terms pending legal review.

            1. HerbLens is a reference tool. It is NOT medical advice. Consult a qualified practitioner before changing your diet, supplements, or medications.
            2. Identification confidence is imperfect — always verify plants using multiple sources before consuming.
            3. Subscriptions auto-renew through your Apple ID unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple ID → Subscriptions.
            4. Your content (scans, notes, preferences) belongs to you. You can export or delete your account from Settings at any time.

            Contact: support@herblens.app
            """
        case .licenses:
            return """
            HerbLens builds on open-source work. Full attribution list pending automated NOTICE generation.

            Libraries (non-exhaustive):
            • supabase-swift — Apache-2.0
            • revenuecat / purchases-ios — MIT
            • PostHog Swift SDK — MIT
            • Kingfisher — MIT

            Licenses are bundled with the app. Email support@herblens.app for a signed NOTICE file.
            """
        }
    }
}

struct LegalDocumentView: View {
    let kind: LegalDocumentKind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                placeholderBanner
                Text(kind.placeholderBody)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholderBanner: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Color.amber)
            Text("Placeholder — replace before TestFlight")
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Color.amber.opacity(0.15))
        )
    }
}

struct SettingsLegalSection: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Legal")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.bottom, Theme.Spacing.xxs)

                ForEach(LegalDocumentKind.allCases, id: \.self) { kind in
                    NavigationLink(value: kind) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Text(kind.title)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Spacer()
                            Image(systemName: Theme.Icon.next)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.Color.textSecondary.opacity(0.6))
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if kind != LegalDocumentKind.allCases.last {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }
}
