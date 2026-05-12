import SwiftUI

struct ValuePropPage: View {
    let onContinue: @Sendable () -> Void

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    MascotBadge(.celebrating, size: 160)
                        .padding(.top, Theme.Spacing.xl)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("HerbLens keeps you informed")
                            .font(Theme.Font.display)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.md)

                        Text("Scan unlimited herbs. Understand what works for you.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        BenefitRow(
                            icon: "leaf.fill",
                            title: "500+ herbs catalogued",
                            description: "From chamomile to ashwagandha — each with uses, safety info, and recipes."
                        )

                        BenefitRow(
                            icon: "shield.checkered",
                            title: "AI safety checks",
                            description: "Instant warnings for drug interactions, allergies, and conditions."
                        )

                        BenefitRow(
                            icon: "chart.bar.fill",
                            title: "Personalized health scores",
                            description: "Every herb scored against your goals so you brew with intent."
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    statBanner
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                PrimaryButton("Almost there", action: onContinue)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 72)
            }
        }
    }

    private var statBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundStyle(Theme.Color.sage)

            Text("78% of users discover a new herb in their first week")
                .font(Theme.Font.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Color.sage.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Color.sage.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.Color.sage)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)

                    Text(description)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ValuePropPage(onContinue: {})
}
