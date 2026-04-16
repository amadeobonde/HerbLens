import SwiftUI

/// Lists the plant's own `Contraindication` entries. Uses the same severity → color
/// mapping as the cross-cutting warnings section for visual consistency.
struct ContraindicationsTab: View {
    let contraindications: [Contraindication]

    var body: some View {
        if contraindications.isEmpty {
            EmptyContraindicationsCard()
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Situations where this plant may not be safe:")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)

                ForEach(contraindications, id: \.condition) { item in
                    ContraindicationRowView(item: item)
                }
            }
        }
    }
}

private struct ContraindicationRowView: View {
    let item: Contraindication

    private var style: WarningStyle { WarningStyle(severity: item.severity) }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: style.iconName)
                .font(.title3)
                .foregroundStyle(style.color)
                .frame(width: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(item.condition)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(item.details)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(style.label.uppercased())
                    .font(Theme.Font.caption.weight(.bold))
                    .foregroundStyle(style.color)
                    .tracking(1.1)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(style.color.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.color.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct EmptyContraindicationsCard: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Theme.Color.sage)
            Text("No known contraindications on file.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Always confirm with your clinician before starting a new herb.")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glass(.card)
    }
}
