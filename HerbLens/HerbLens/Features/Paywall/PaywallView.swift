import SwiftUI

/// Monetization entry point. Presented modally from Settings, Scan (quota), Recipes,
/// Chat, and HerbProfile (paywalled tabs). Reads services from `@Environment` and keeps
/// its own `PaywallViewModel` so the view model's lifecycle matches the sheet.
///
/// Layout: full-bleed apothecary hero → two-column pricing grid → "Includes" feature
/// card → primary CTA (start trial) → ghost restore → tertiary "Maybe later" close →
/// legal footer.
struct PaywallView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PaywallViewModel()

    var body: some View {
        ZStack {
            Theme.Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    PaywallHeroView()

                    VStack(spacing: Theme.Spacing.md) {
                        offeringsSection
                        PaywallFeatureList()
                        primaryCTA
                        restoreButton
                        if let message = viewModel.errorMessage {
                            errorBanner(message)
                        }
                        maybeLater
                        legalFooter
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .scrollIndicators(.hidden)

            if viewModel.purchaseSucceeded {
                PaywallSuccessOverlay {
                    viewModel.acknowledgeSuccess()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: Theme.Icon.close)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Color.bone)
                        .padding(8)
                        .background(Circle().fill(Theme.Color.charcoal.opacity(0.35)))
                }
                .accessibilityLabel("Close")
            }
        }
        .task {
            await viewModel.load(subscriptions: dependencies.subscriptions)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var offeringsSection: some View {
        if viewModel.isLoadingOfferings {
            HStack(spacing: Theme.Spacing.xs) {
                ProgressView()
                Text("Loading plans…")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if viewModel.sortedOfferings.isEmpty {
            GlassCard(tone: .subtle) {
                Text("Plans aren't available right now.")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        } else {
            PaywallPricingGrid(
                offerings: viewModel.sortedOfferings,
                selectedPackageID: viewModel.selectedPackageID,
                isBestValue: viewModel.isBestValue
            ) { offering in
                viewModel.selectedPackageID = offering.packageID
            }
        }
    }

    @ViewBuilder
    private var primaryCTA: some View {
        let disabled = viewModel.selectedOffering == nil
            || viewModel.isPurchasing
            || viewModel.isRestoring
        let title = ctaTitle
        let selectedID = viewModel.selectedPackageID
        ZStack {
            PrimaryButton(title, variant: .filled, isDisabled: disabled) {
                guard let packageID = selectedID else { return }
                Task { @MainActor in
                    await viewModel.purchase(
                        packageID: packageID,
                        subscriptions: dependencies.subscriptions
                    )
                }
            }
            if viewModel.isPurchasing {
                ProgressView()
                    .tint(Theme.Color.bone)
            }
        }
    }

    private var restoreButton: some View {
        PrimaryButton(
            "Restore purchases",
            variant: .ghost,
            isDisabled: viewModel.isPurchasing || viewModel.isRestoring
        ) {
            Task { @MainActor in
                await viewModel.restore(subscriptions: dependencies.subscriptions)
            }
        }
    }

    private var maybeLater: some View {
        Button {
            dismiss()
        } label: {
            Text("Maybe later")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Maybe later")
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Color.ember)
            .padding(Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                    .fill(Theme.Color.ember.opacity(0.1))
            )
    }

    private var legalFooter: some View {
        Text("Cancel anytime in Settings → Apple ID → Subscriptions. Payment charged to your Apple ID on confirmation; subscription auto-renews unless cancelled at least 24 hours before the end of the period.")
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Color.textSecondary.opacity(0.8))
            .multilineTextAlignment(.leading)
    }

    private var ctaTitle: String {
        if let trialDays = viewModel.selectedOffering?.trialDays, trialDays > 0 {
            return "Start \(trialDays)-day free trial"
        }
        return "Start free trial"
    }
}

#Preview("Paywall — mock free tier") {
    PaywallView()
        .environment(\.dependencies, .mock)
}
