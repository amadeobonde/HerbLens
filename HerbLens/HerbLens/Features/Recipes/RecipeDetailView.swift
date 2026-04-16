import SwiftUI

/// Full brew-card detail. Tea recipes show hero + ingredients (always) and a
/// collapsed preview of the steps gated behind premium. Tinctures are fully
/// locked for free users. Unlocked recipes offer a `PrimaryButton("Start brewing")`
/// that presents the Duolingo-style `RecipePlayerView`.
struct RecipeDetailView: View {
    let recipe: Recipe
    let isUnlocked: Bool
    let madeStore: MadeRecipesStore
    let onTapUpgrade: () -> Void

    @State private var showingPlayer: Bool = false
    @State private var showingFinish: Bool = false
    @State private var finishedState: RecipePlayerState?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                heroBlock

                GlassCard(tone: .subtle) {
                    metadataRow
                }
                .padding(.horizontal, Theme.Spacing.md)

                if shouldLockEverything {
                    RecipePremiumLock(scope: .fullTincture, onTapUpgrade: onTapUpgrade)
                        .padding(.horizontal, Theme.Spacing.md)
                } else {
                    ingredientsSection
                        .padding(.horizontal, Theme.Spacing.md)
                    stepsSection
                        .padding(.horizontal, Theme.Spacing.md)
                    if isUnlocked {
                        PrimaryButton("Start brewing") {
                            RecipeHaptics.start()
                            showingPlayer = true
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .shadow(Theme.Shadow.float)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(backdrop)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPlayer) {
            NavigationStack {
                RecipePlayerView(
                    recipe: recipe,
                    onFinish: { state in
                        finishedState = state
                        showingPlayer = false
                        showingFinish = true
                    },
                    onClose: {
                        showingPlayer = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingFinish) {
            finishedState = nil
        } content: {
            RecipeFinishView(
                recipe: recipe,
                madeStore: madeStore,
                onSaved: { _ in },
                onDismiss: { showingFinish = false }
            )
        }
    }

    private var shouldLockEverything: Bool {
        recipe.type == .tincture && !isUnlocked
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Theme.Color.sage.opacity(0.18), Theme.Color.bone],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroBlock: some View {
        if let slug = RecipeImageLookup.assetName(for: recipe) {
            HeroPhoto(named: "Recipes/\(slug)", height: 260)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Theme.Color.sage.opacity(0.7), Theme.Color.forest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: recipe.type == .tea ? "cup.and.saucer.fill" : "drop.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.bone.opacity(0.35))
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var metadataRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                metaChip(icon: "clock", label: "Prep", value: recipe.prepTime)
                if let steep = recipe.steepOrCureTime {
                    metaChip(icon: Theme.Icon.timer,
                             label: recipe.type == .tea ? "Steep" : "Cure",
                             value: steep)
                }
                metaChip(icon: "drop", label: "Yield", value: recipe.yield)
                metaChip(icon: "graduationcap",
                         label: "Level",
                         value: recipe.difficulty.rawValue.capitalized)
            }
        }
    }

    private func metaChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.forest)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text(value)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .glass(.capsule)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Ingredients")
            GlassCard(tone: .standard) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(recipe.ingredients, id: \.name) { ingredient in
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(Theme.Color.sage)
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading) {
                                Text("\(ingredient.amount) \(ingredient.name)")
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                if let notes = ingredient.notes {
                                    Text(notes)
                                        .font(Theme.Font.caption)
                                        .foregroundStyle(Theme.Color.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Steps")
            if isUnlocked {
                GlassCard(tone: .standard) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        ForEach(Array(recipe.steps.prefix(3).enumerated()), id: \.offset) { index, step in
                            stepPreviewRow(index: index, step: step)
                        }
                        if recipe.steps.count > 3 {
                            Text("+ \(recipe.steps.count - 3) more steps")
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
            } else {
                if let first = recipe.steps.first {
                    GlassCard(tone: .standard) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Step 1 of \(recipe.steps.count)")
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                            Text(first.instruction)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textPrimary)
                        }
                    }
                }
                RecipePremiumLock(scope: .teaSteps, onTapUpgrade: onTapUpgrade)
            }
        }
    }

    private func stepPreviewRow(index: Int, step: RecipeStep) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("\(index + 1)")
                .font(Theme.Font.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.bone)
                .frame(width: 24, height: 24)
                .background(Theme.Color.sage, in: .circle)
            Text(step.instruction)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.title)
            .foregroundStyle(Theme.Color.textPrimary)
    }
}

#Preview("Tea — locked") {
    NavigationStack {
        RecipeDetailView(
            recipe: RecipePreviewFixtures.teas.first!,
            isUnlocked: false,
            madeStore: MadeRecipesStore(defaults: .standard),
            onTapUpgrade: {}
        )
    }
}

#Preview("Tea — unlocked") {
    NavigationStack {
        RecipeDetailView(
            recipe: RecipePreviewFixtures.teas.first!,
            isUnlocked: true,
            madeStore: MadeRecipesStore(defaults: .standard),
            onTapUpgrade: {}
        )
    }
}

#Preview("Tincture — locked") {
    NavigationStack {
        RecipeDetailView(
            recipe: RecipePreviewFixtures.localTinctures[0],
            isUnlocked: false,
            madeStore: MadeRecipesStore(defaults: .standard),
            onTapUpgrade: {}
        )
    }
}
