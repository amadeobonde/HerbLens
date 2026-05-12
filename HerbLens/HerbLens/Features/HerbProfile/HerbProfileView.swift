import SwiftUI

/// Plant-detail screen — design-system reskin.
/// Hero photo cap → mascot badge → glass-card stack (identity, health, uses,
/// contraindications, recipes) → related-plants carousel. Chat + Paywall
/// routing is injected via closures so this feature owns no cross-cutting nav.
struct HerbProfileView: View {
    let plantID: String
    let onAskAboutPlant: @Sendable (String) -> Void
    let onRequestPaywall: @Sendable () -> Void

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
    let onAskAboutPlant: @Sendable (String) -> Void
    let onRequestPaywall: @Sendable () -> Void

    private var isPremium: Bool { payload.tier == .premium }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock

                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    IdentityCard(plant: payload.plant)
                    HealthScoreCard(score: payload.healthScore)
                    UsesGridCard(uses: payload.plant.uses, description: payload.plant.description)

                    if !payload.plant.contraindications.isEmpty {
                        ContraindicationsCard(items: payload.plant.contraindications)
                    }

                    RecipesCarouselCard(
                        recipes: payload.plant.recipes,
                        isPremium: isPremium,
                        onRequestPaywall: onRequestPaywall
                    )

                    AskBambooCard(plant: payload.plant, onAskAboutPlant: onAskAboutPlant)

                    if !payload.relatedPlants.isEmpty {
                        RelatedPlantsSection(plants: payload.relatedPlants)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
                .padding(.top, -40) // pull mascot/cards up under hero cap
            }
        }
        .scrollIndicators(.hidden)
    }

    private var heroBlock: some View {
        ZStack(alignment: .bottom) {
            HeroPhoto(named: payload.plant.imageUrl, height: heroHeight)

            // Mascot overlaps the bottom edge of the hero by ~40pt.
            MascotBadge(.teacher, size: 96)
                .offset(y: 40)
        }
        .padding(.bottom, 0)
    }
}

// MARK: - Identity card

private struct IdentityCard: View {
    let plant: Plant

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(plant.category.uppercased())
                    .font(Theme.Font.caption.weight(.semibold))
                    .foregroundStyle(Theme.Color.sage)
                    .tracking(1.4)

                Text(plant.commonName)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)

                if let scientific = plant.alternateNames.first {
                    Text(scientific)
                        .font(Theme.Font.body)
                        .italic()
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                if !plant.description.isEmpty {
                    Text(plant.description)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.xxs)
                }
            }
        }
    }
}

// MARK: - Health score card

private struct HealthScoreCard: View {
    let score: HealthScore

    private var ringColor: Color {
        HealthRingStyle(score: score.overallScore).color
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .center, spacing: Theme.Spacing.lg) {
                    RingMetric(
                        value: Double(score.overallScore),
                        total: 100,
                        label: "Match",
                        color: ringColor
                    )
                    .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Health match")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(HealthRingStyle(score: score.overallScore).label.capitalized)
                            .font(Theme.Font.callout.weight(.semibold))
                            .foregroundStyle(ringColor)
                        Text("Based on your profile and goals.")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                if !score.goalBreakdown.isEmpty {
                    Divider().background(Theme.Color.forest.opacity(0.15))

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(score.goalBreakdown.prefix(2), id: \.goalName) { item in
                            GoalBreakdownRowCompact(item: item)
                        }
                    }
                }

                if !score.warnings.isEmpty {
                    WarningsSection(warnings: score.warnings, isPremium: false)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
        }
    }
}

private struct GoalBreakdownRowCompact: View {
    let item: GoalBreakdown

    private var style: HealthRingStyle { HealthRingStyle(score: item.relevanceScore) }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Circle()
                .fill(style.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.goalName)
                    .font(Theme.Font.callout.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(item.reason)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: Theme.Spacing.xs)

            Text("\(item.relevanceScore)")
                .font(Theme.Font.headline.monospacedDigit())
                .foregroundStyle(style.color)
        }
    }
}

// MARK: - Uses 2-col grid card

private struct UsesGridCard: View {
    let uses: [PlantUse]
    let description: String

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Uses", systemImage: "leaf.fill")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                if uses.isEmpty {
                    Text("No catalogued uses yet.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                        ForEach(uses, id: \.description) { use in
                            UseCell(use: use)
                        }
                    }
                }
            }
        }
    }
}

private struct UseCell: View {
    let use: PlantUse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            HStack(spacing: Theme.Spacing.xxs) {
                Text(use.category)
                    .font(Theme.Font.caption.weight(.bold))
                    .foregroundStyle(Theme.Color.sage)
                    .tracking(1.0)
                Spacer(minLength: 0)
                if use.accessTier == .premium {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(Theme.Color.amber)
                        .accessibilityLabel("Premium content")
                }
            }
            Text(use.description)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Color.sage.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Color.sage.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Contraindications card

private struct ContraindicationsCard: View {
    let items: [Contraindication]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Watch-outs", systemImage: "exclamationmark.shield.fill")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.ember)

                ForEach(items, id: \.condition) { item in
                    HerbProfileContraindicationRow(item: item)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Color.ember.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct HerbProfileContraindicationRow: View {
    let item: Contraindication

    private var style: WarningStyle { WarningStyle(severity: item.severity) }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Circle()
                .fill(style.color)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.condition)
                    .font(Theme.Font.callout.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(item.details)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(style.label.uppercased())
                    .font(Theme.Font.caption.weight(.bold))
                    .foregroundStyle(style.color)
                    .tracking(1.0)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Recipes carousel card (premium-gated)

private struct RecipesCarouselCard: View {
    let recipes: [Recipe]
    let isPremium: Bool
    let onRequestPaywall: @Sendable () -> Void

    /// Free tier sees the first recipe + lock CTA; premium sees the full horizontal scroll.
    private var visibleRecipes: [Recipe] {
        guard !recipes.isEmpty else { return [] }
        return isPremium ? recipes : Array(recipes.prefix(1))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Recipes", systemImage: "cup.and.saucer.fill")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                if recipes.isEmpty {
                    Text("No recipes catalogued yet.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(visibleRecipes) { recipe in
                                RecipeCarouselCard(recipe: recipe)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xxs)
                    }

                    if !isPremium && recipes.count > 1 {
                        PrimaryButton("Unlock all recipes", variant: .ghost) {
                            onRequestPaywall()
                        }
                    }
                }
            }
        }
    }
}

private struct RecipeCarouselCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Color.sage.opacity(0.18))

                Image(systemName: recipe.type == .tea ? "cup.and.saucer.fill" : "drop.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.Color.forest)
            }
            .frame(width: 200, height: 110)

            Text(recipe.title)
                .font(Theme.Font.callout.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(2)

            Text("\(recipe.prepTime) prep · \(recipe.yield)")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 200, alignment: .leading)
    }
}

// MARK: - Ask Bamboo card

private struct AskBambooCard: View {
    let plant: Plant
    let onAskAboutPlant: @Sendable (String) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Ask Bamboo", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                Text("Premium AI herbalist with context on your health profile.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                if !plant.suggestedPrompts.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ForEach(plant.suggestedPrompts.prefix(3), id: \.self) { prompt in
                            Button {
                                onAskAboutPlant(plant.id)
                            } label: {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "sparkle")
                                        .foregroundStyle(Theme.Color.amber)
                                    Text(prompt)
                                        .font(Theme.Font.body)
                                        .foregroundStyle(Theme.Color.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(Theme.Color.textSecondary)
                                }
                                .padding(Theme.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                        .fill(Theme.Color.sage.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                PrimaryButton("Start a new conversation") {
                    onAskAboutPlant(plant.id)
                }
            }
        }
    }
}

// MARK: - Related plants

private struct RelatedPlantsSection: View {
    let plants: [Plant]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Related plants")
                .padding(.horizontal, -Theme.Spacing.md) // SectionHeader has its own h-padding

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(plants) { plant in
                        RelatedPlantCard(plant: plant)
                    }
                }
                .padding(.vertical, Theme.Spacing.xxs)
            }
        }
    }
}

private struct RelatedPlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Color.sage.opacity(0.18))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.forest)
            }
            .frame(width: 140, height: 100)

            Text(plant.commonName)
                .font(Theme.Font.callout.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(1)

            Text(plant.category)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 140, alignment: .leading)
    }
}

// MARK: - Supporting states

private struct HerbProfileLoadingPlaceholder: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            MascotBadge(.teacher, size: 120)
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
    let onRetry: @Sendable () -> Void

    var body: some View {
        EmptyStateView(
            mascot: .sleeping,
            title: "Couldn't load this plant.",
            subtitle: String(describing: error),
            ctaTitle: "Try again",
            action: onRetry
        )
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
