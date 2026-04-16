import SwiftUI

/// List of `Warning` items color-coded by severity via `WarningStyle`. Premium callers
/// can pass a `premiumGuidance` callout block that renders beneath the rows (mirrors the
/// "deeper reasoning from Gemini 3 Pro" premium glow promise).
struct WarningsSection: View {
    let warnings: [Warning]
    let isPremium: Bool

    var body: some View {
        if warnings.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionTitle(text: "Watch-outs", systemImage: "exclamationmark.shield.fill")

                ForEach(warnings, id: \.message) { warning in
                    WarningRow(warning: warning)
                }

                if isPremium {
                    PremiumCallout()
                }
            }
        }
    }
}

struct WarningRow: View {
    let warning: Warning

    private var style: WarningStyle { WarningStyle(severity: warning.severity) }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: style.iconName)
                .font(.title3)
                .foregroundStyle(style.color)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(style.label)
                        .font(Theme.Font.caption.weight(.bold))
                        .foregroundStyle(style.color)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(style.color.opacity(0.15)))
                    Text(warningTypeLabel)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Text(warning.message)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(style.color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var warningTypeLabel: String {
        switch warning.type {
        case .allergy: "Allergy"
        case .medicationInteraction: "Medication interaction"
        case .condition: "Condition"
        }
    }
}

private struct PremiumCallout: View {
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.Color.amber)
            Text("Premium insight — Gemini 3 Pro personalized this risk summary for your health profile.")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.subtle)
    }
}

struct SectionTitle: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.Color.textPrimary)
    }
}
