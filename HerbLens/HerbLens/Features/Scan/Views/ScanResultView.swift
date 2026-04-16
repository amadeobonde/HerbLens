import SwiftUI

/// Post-identify result screen. `HeroPhoto` cap with a celebrating mascot overlap,
/// then three stacked `GlassCard`s (Identity with `RingMetric`s, Uses, Watch-out).
/// Low-confidence identifications surface the candidate chip row above the actions.
struct ScanResultView: View {
    let result: ScanResult
    let tier: SubscriptionTier
    let onSave: @Sendable () -> Void
    let onScanAnother: @Sendable () -> Void
    let onPickCandidate: (Plant) -> Void
    let onOpenVault: (@Sendable () -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    heroSection
                        .padding(.bottom, Theme.Spacing.xl) // space for mascot overlap
                    identityCard
                        .padding(.horizontal, Theme.Spacing.md)
                    usesCard
                        .padding(.horizontal, Theme.Spacing.md)
                    if let contraindications = displayPlant?.contraindications, !contraindications.isEmpty {
                        watchOutCard(contraindications)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                    if result.isLowConfidence, result.identification.suggestedMatches.count > 1 {
                        CandidateChipsRow(
                            candidates: result.identification.suggestedMatches,
                            selectedID: result.selectedPlant?.id,
                            onSelect: onPickCandidate
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    Color.clear.frame(height: 140) // keep content above the sticky bar
                }
                .padding(.top, Theme.Spacing.xs)
            }

            stickyActions
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            HeroPhoto(uiImage: result.image, height: 320)

            MascotBadge(.celebrating, size: 160)
                .offset(y: 40)
                .shadow(Theme.Shadow.float)
        }
    }

    // MARK: - Identity card

    private var identityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayPlant?.commonName ?? result.identification.rawIdentification ?? "Unknown plant")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    if let scientific = displayPlant?.alternateNames.first {
                        Text(scientific)
                            .font(Theme.Font.body)
                            .italic()
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }

                HStack(spacing: Theme.Spacing.md) {
                    RingMetric(
                        value: clampedConfidence,
                        label: "Match",
                        color: confidenceColor,
                        size: 84
                    )
                    RingMetric(
                        value: healthScoreValue,
                        label: "Health",
                        color: Theme.Color.sage,
                        size: 84
                    )
                    RingMetric(
                        value: goalsValue,
                        label: "Goals",
                        color: Theme.Color.amber,
                        size: 84
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if let description = displayPlant?.description {
                    Text(description)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Uses card

    private var usesCard: some View {
        GlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Traditional uses")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                if let uses = displayPlant?.uses, !uses.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm),
                                  GridItem(.flexible(), spacing: Theme.Spacing.sm)],
                        spacing: Theme.Spacing.sm
                    ) {
                        ForEach(Array(uses.enumerated()), id: \.offset) { _, use in
                            useCell(use)
                        }
                    }
                } else {
                    Text("No documented uses yet.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
    }

    private func useCell(_ use: PlantUse) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(use.category)
                .font(Theme.Font.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.forest)
            Text(use.description)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Color.bone.opacity(0.6))
        )
    }

    // MARK: - Watch-out card

    private func watchOutCard(_ contraindications: [Contraindication]) -> some View {
        GlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: Theme.Icon.error)
                        .foregroundStyle(Theme.Color.ember)
                    Text("Watch-out")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                }

                ForEach(Array(contraindications.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.condition)
                            .font(Theme.Font.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(item.details)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Color.ember.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Sticky actions

    private var stickyActions: some View {
        VStack(spacing: Theme.Spacing.xs) {
            PrimaryButton(
                "Save to Vault",
                isDisabled: result.selectedPlant == nil,
                action: onSave
            )
            HStack(spacing: Theme.Spacing.sm) {
                PrimaryButton(
                    tier == .premium ? "Scan another instantly" : "Scan another",
                    variant: .ghost,
                    action: onScanAnother
                )
                if let onOpenVault {
                    PrimaryButton("Open Vault", variant: .ghost, action: onOpenVault)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Color.clear
                .glass(.subtle)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        )
        .shadow(Theme.Shadow.float)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Derived values

    private var displayPlant: Plant? {
        result.selectedPlant ?? result.identification.suggestedMatches.first
    }

    private var clampedConfidence: Double {
        min(max(result.identification.confidence, 0), 1)
    }

    private var confidenceColor: Color {
        if clampedConfidence >= 0.85 { return Theme.Color.forest }
        if clampedConfidence >= ScanResult.lowConfidenceThreshold { return Theme.Color.sage }
        if clampedConfidence >= 0.5 { return Theme.Color.amber }
        return Theme.Color.ember
    }

    private var healthScoreValue: Double {
        guard let plant = displayPlant else { return 0 }
        return Double(plant.healthScore.overallScore) / 100.0
    }

    private var goalsValue: Double {
        guard let plant = displayPlant, !plant.healthScore.goalBreakdown.isEmpty else {
            return 0
        }
        let top = plant.healthScore.goalBreakdown
            .map(\.relevanceScore)
            .max() ?? 0
        return Double(top) / 100.0
    }
}
