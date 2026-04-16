import SwiftUI

/// Full brew-card detail. Tea recipes show hero + metadata + ingredients
/// (always) and gate steps/timer behind premium. Tinctures are fully locked
/// for free users — the hero + metadata tease, a `.fullTincture` upsell
/// replaces the body.
struct RecipeDetailView: View {
    let recipe: Recipe
    let isUnlocked: Bool
    let madeStore: MadeRecipesStore
    let onTapUpgrade: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                hero
                metadataRow
                if shouldLockEverything {
                    RecipePremiumLock(scope: .fullTincture, onTapUpgrade: onTapUpgrade)
                } else {
                    ingredientsSection
                    stepsSection
                    if let minutes = SteepDurationParser.minutes(from: recipe.steepOrCureTime), isUnlocked {
                        RecipeTimerView(totalMinutes: minutes)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Color.bone)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var shouldLockEverything: Bool {
        recipe.type == .tincture && !isUnlocked
    }

    private var hero: some View {
        Group {
            if let image = RecipeImageLookup.image(for: recipe) {
                image
                    .resizable()
                    .aspectRatio(3 / 2, contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Theme.Color.sage.opacity(0.7), Theme.Color.forest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .aspectRatio(3 / 2, contentMode: .fill)
                .overlay {
                    Image(systemName: recipe.type == .tea ? "cup.and.saucer.fill" : "drop.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.Color.bone.opacity(0.3))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var metadataRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                metaChip(icon: "clock", label: "Prep", value: recipe.prepTime)
                if let steep = recipe.steepOrCureTime {
                    metaChip(icon: "timer", label: recipe.type == .tea ? "Steep" : "Cure", value: steep)
                }
                metaChip(icon: "drop", label: "Yield", value: recipe.yield)
                metaChip(icon: "graduationcap", label: "Level", value: recipe.difficulty.rawValue.capitalized)
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

    @ViewBuilder private var stepsSection: some View {
        sectionHeader("Steps")
        if isUnlocked {
            RecipeStepsPager(
                steps: recipe.steps,
                isMade: madeStore.isMade(recipe.id),
                onToggleMade: { madeStore.toggle(recipe.id) }
            )
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if let first = recipe.steps.first {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Step 1 of \(recipe.steps.count)")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(first.instruction)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass(.card)
                }
                RecipePremiumLock(scope: .teaSteps, onTapUpgrade: onTapUpgrade)
            }
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
