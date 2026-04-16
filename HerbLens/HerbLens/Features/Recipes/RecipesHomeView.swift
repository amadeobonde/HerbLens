import SwiftUI

/// Root view for the Brew tab. Loads recipes via `PlantsRepository.featured()`,
/// falls back to `RecipePreviewFixtures.allRecipes` in Xcode Previews, and
/// splits the browse surface into a brewing mascot header, filter chips, and
/// two `GlassCard`-grid sections (Teas / Tinctures).
struct RecipesHomeView: View {
    enum Filter: Hashable, CaseIterable {
        case all, teas, tinctures

        var title: String {
            switch self {
            case .all: "All"
            case .teas: "Teas"
            case .tinctures: "Tinctures"
            }
        }
    }

    @Environment(\.dependencies) private var dependencies
    @State private var recipes: [Recipe] = []
    @State private var isLoading: Bool = true
    @State private var filter: Filter = .all
    @State private var tier: SubscriptionTier = .free
    @State private var selectedRecipe: Recipe?
    @State private var madeStore = MadeRecipesStore(defaults: .standard)

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && recipes.isEmpty {
                    loadingState
                } else if recipes.isEmpty {
                    emptyState
                } else {
                    contentScroll
                }
            }
            .background(backdrop)
            .navigationDestination(item: $selectedRecipe) { recipe in
                RecipeDetailView(
                    recipe: recipe,
                    isUnlocked: isUnlocked(recipe),
                    madeStore: madeStore,
                    onTapUpgrade: handleUpgradeTap
                )
            }
        }
        .task {
            await refreshTier()
            await loadRecipes()
        }
    }

    // MARK: - Derived lists

    private var teas: [Recipe] { recipes.filter { $0.type == .tea } }
    private var tinctures: [Recipe] { recipes.filter { $0.type == .tincture } }
    private var teasVisible: Bool { filter == .all || filter == .teas }
    private var tincturesVisible: Bool { filter == .all || filter == .tinctures }

    // MARK: - Subviews

    private var backdrop: some View {
        LinearGradient(
            colors: [Theme.Color.sage.opacity(0.18), Theme.Color.bone],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                filterChips
                if teasVisible, !teas.isEmpty {
                    SectionHeader("Teas")
                    teasGrid
                }
                if tincturesVisible, !tinctures.isEmpty {
                    SectionHeader("Tinctures")
                    tincturesGrid
                }
            }
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.sm)
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.xs) {
            MascotBadge(.brewing, size: 120)
            Text("Brew, sip, learn")
                .font(Theme.Font.display)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Pick a brew, follow along.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var filterChips: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(Filter.allCases, id: \.self) { option in
                Button {
                    withAnimation(Theme.Motion.snappy) { filter = option }
                } label: {
                    Text(option.title)
                        .font(Theme.Font.callout)
                        .fontWeight(filter == option ? .semibold : .regular)
                        .foregroundStyle(filter == option ? Theme.Color.bone : Theme.Color.forest)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(filter == option ? Theme.Color.forest : .clear, in: .capsule)
                        .glass(.capsule)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var teasGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(teas) { recipe in
                Button { selectedRecipe = recipe } label: {
                    RecipeCardView(recipe: recipe, isLocked: !isUnlocked(recipe))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private var tincturesGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(tinctures) { recipe in
                Button { selectedRecipe = recipe } label: {
                    TinctureCardView(recipe: recipe)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private var loadingState: some View {
        EmptyStateView(
            mascot: .brewing,
            title: "Warming the kettle",
            subtitle: "Pulling today's brews from the apothecary."
        )
    }

    private var emptyState: some View {
        EmptyStateView(
            mascot: .sleeping,
            title: "No brews yet",
            subtitle: "We'll pour new recipes here as soon as they land.",
            ctaTitle: "Try again",
            action: {
                Task { await loadRecipes() }
            }
        )
    }

    // MARK: - Data

    private func loadRecipes() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let plants = try await dependencies.plants.featured()
            let serverRecipes = plants.flatMap(\.recipes)
            if serverRecipes.isEmpty {
                recipes = RecipePreviewFixtures.allRecipes
            } else {
                let tincturesFromServer = serverRecipes.contains { $0.type == .tincture }
                recipes = tincturesFromServer
                    ? serverRecipes
                    : serverRecipes + RecipePreviewFixtures.localTinctures
            }
        } catch {
            recipes = RecipePreviewFixtures.allRecipes
        }
    }

    private func refreshTier() async {
        tier = await dependencies.subscriptions.currentTier()
    }

    // MARK: - Gating

    private func isUnlocked(_ recipe: Recipe) -> Bool {
        if tier == .premium { return true }
        if recipe.type == .tincture { return false }
        return recipe.accessTier == .free
    }

    private func handleUpgradeTap() {
        Task {
            do {
                let offerings = try await dependencies.subscriptions.offerings()
                guard let package = offerings.first else { return }
                let newTier = try await dependencies.subscriptions.purchase(packageID: package.packageID)
                tier = newTier
            } catch {
                // Paywall feature (Instance 10) will surface this UX; for now the
                // button fails silently so we don't block this branch's local build.
            }
        }
    }
}

#Preview {
    RecipesHomeView()
        .environment(\.dependencies, .mock)
}
