import SwiftUI

/// Plant-detail screen. Hero → Liquid-Glass health-score ring → per-goal breakdown →
/// warnings → tabs. Chat + Paywall routing is injected via closures so this feature
/// owns no cross-cutting navigation.
struct HerbProfileView: View {
    let plantID: String
    let onAskAboutPlant: (String) -> Void
    let onRequestPaywall: () -> Void

    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: HerbProfileViewModel?

    private let heroHeight: CGFloat = 320

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = HerbProfileViewModel(
                    plantID: plantID,
                    plants: dependencies.plants,
                    subscriptions: dependencies.subscriptions,
                    auth: dependencies.auth
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            switch viewModel.state {
            case .idle, .loading:
                HerbProfileLoadingPlaceholder()
            case .loaded(let payload):
                LoadedBody(
                    payload: payload,
                    heroHeight: heroHeight,
                    selectedTab: Binding(
                        get: { viewModel.selectedTab },
                        set: { viewModel.selectedTab = $0 }
                    ),
                    isBreakdownExpanded: viewModel.isBreakdownExpanded,
                    onToggleBreakdown: { viewModel.toggleBreakdown() },
                    onAskAboutPlant: onAskAboutPlant,
                    onRequestPaywall: onRequestPaywall
                )
            case .failed(let error):
                HerbProfileErrorState(error: error) { Task { await viewModel.retry() } }
            }
        } else {
            HerbProfileLoadingPlaceholder()
        }
    }
}

// MARK: - Loaded body

private struct LoadedBody: View {
    let payload: HerbProfilePayload
    let heroHeight: CGFloat
    @Binding var selectedTab: HerbTab
    let isBreakdownExpanded: Bool
    let onToggleBreakdown: () -> Void
    let onAskAboutPlant: (String) -> Void
    let onRequestPaywall: () -> Void

    private var isPremium: Bool { payload.tier == .premium }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeroParallaxHeader(plant: payload.plant, height: heroHeight)

                VStack(spacing: Theme.Spacing.lg) {
                    scoreBlock
                    warningsBlock
                    tabBlock
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var scoreBlock: some View {
        VStack(spacing: Theme.Spacing.md) {
            HealthScoreRing(
                score: payload.healthScore.overallScore,
                isPremium: isPremium,
                isExpanded: isBreakdownExpanded,
                onToggle: {
                    withAnimation(.spring(duration: 0.4)) { onToggleBreakdown() }
                }
            )
            GoalBreakdownSection(
                breakdown: payload.healthScore.goalBreakdown,
                isExpanded: isBreakdownExpanded
            )
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.45), value: isBreakdownExpanded)
    }

    @ViewBuilder
    private var warningsBlock: some View {
        if !payload.healthScore.warnings.isEmpty {
            WarningsSection(warnings: payload.healthScore.warnings, isPremium: isPremium)
        }
    }

    private var tabBlock: some View {
        VStack(spacing: Theme.Spacing.md) {
            HerbTabSelector(selected: $selectedTab)

            switch selectedTab {
            case .uses:
                UsesTab(uses: payload.plant.uses, description: payload.plant.description)
            case .contraindications:
                ContraindicationsTab(contraindications: payload.plant.contraindications)
            case .recipes:
                RecipesTab(
                    recipes: payload.plant.recipes,
                    isPremium: isPremium,
                    onRequestPaywall: onRequestPaywall
                )
            case .ask:
                AskTab(plant: payload.plant, onAskAboutPlant: onAskAboutPlant)
            }
        }
    }
}

// MARK: - Supporting states

private struct HerbProfileLoadingPlaceholder: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView().tint(Theme.Color.forest)
            Text("Loading plant details…")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HerbProfileErrorState: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Color.ember)
            Text("Couldn't load this plant.")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(String(describing: error))
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button("Try again", action: onRetry)
                .buttonStyle(.glassProminent)
                .tint(Theme.Color.forest)
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Previews

#Preview("Loaded — free tier") {
    NavigationStack {
        HerbProfileView(
            plantID: SampleData.chamomile.id,
            onAskAboutPlant: { _ in },
            onRequestPaywall: {}
        )
    }
    .environment(\.dependencies, .mock)
}

#Preview("Loaded — premium tier") {
    NavigationStack {
        HerbProfileView(
            plantID: SampleData.chamomile.id,
            onAskAboutPlant: { _ in },
            onRequestPaywall: {}
        )
    }
    .environment(\.dependencies, .herbProfilePreviewPremium)
}

#Preview("Error state") {
    NavigationStack {
        HerbProfileView(
            plantID: "nonexistent-id",
            onAskAboutPlant: { _ in },
            onRequestPaywall: {}
        )
    }
    .environment(\.dependencies, .mock)
}

// MARK: - Preview helpers

private extension AppDependencies {
    static var herbProfilePreviewPremium: AppDependencies {
        AppDependencies(
            auth: MockServices.Auth(),
            plants: MockServices.Plants(),
            scans: MockServices.Scans(),
            chat: MockServices.Chat(),
            subscriptions: HerbProfilePremiumStub(),
            healthProfile: MockServices.HealthProfileRepo()
        )
    }
}

private struct HerbProfilePremiumStub: SubscriptionService {
    func currentTier() async -> SubscriptionTier { .premium }
    func offerings() async throws -> [Offering] { SampleData.offerings }
    func purchase(packageID: String) async throws -> SubscriptionTier { .premium }
    func restore() async throws -> SubscriptionTier { .premium }
}
