import SwiftUI

/// Duolingo-style step-by-step brewing player. Top: progress pips. Mid: step
/// card with optional tip. Bottom: per-step circular timer + transport. Swipe
/// left to advance (gated on timed steps), swipe right to go back.
struct RecipePlayerView: View {
    let recipe: Recipe
    let onFinish: (RecipePlayerState) -> Void
    let onClose: () -> Void

    @State private var state: RecipePlayerState

    init(
        recipe: Recipe,
        onFinish: @escaping (RecipePlayerState) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.recipe = recipe
        self.onFinish = onFinish
        self.onClose = onClose
        _state = State(initialValue: RecipePlayerState(steps: recipe.steps))
    }

    var body: some View {
        ZStack(alignment: .top) {
            backdrop
            content
            if let chip = state.boundaryChip {
                boundaryChipView(chip)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if let snackbar = state.snackbar {
                snackbarView(snackbar)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Theme.Motion.snappy, value: state.boundaryChip)
        .animation(Theme.Motion.snappy, value: state.snackbar)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onClose) {
                    Image(systemName: Theme.Icon.close)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
            }
        }
        .onChange(of: state.didReachEnd) { _, reached in
            if reached { onFinish(state) }
        }
        .onChange(of: state.timerModel?.state) { _, newValue in
            if newValue == .completed { state.handleTimerCompletion() }
        }
        .onChange(of: state.snackbar) { _, value in
            guard value != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                state.clearSnackbar()
            }
        }
        .onChange(of: state.boundaryChip) { _, value in
            guard value != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1200))
                state.clearBoundaryChip()
            }
        }
    }

    // MARK: - Sections

    private var content: some View {
        VStack(spacing: Theme.Spacing.lg) {
            progressPips
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)

            stepCard
                .padding(.horizontal, Theme.Spacing.md)

            timerArea
                .padding(.horizontal, Theme.Spacing.md)

            Spacer(minLength: 0)
        }
        .gesture(swipeGesture)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Theme.Color.sage.opacity(0.18), Theme.Color.bone],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var progressPips: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(0..<recipe.steps.count, id: \.self) { index in
                Capsule()
                    .fill(pipColor(for: index))
                    .frame(height: 8)
                    .overlay(pipPulse(for: index))
                    .animation(Theme.Motion.snappy, value: state.currentIndex)
                    .animation(Theme.Motion.snappy, value: state.completedIndices)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func pipPulse(for index: Int) -> some View {
        if index == state.currentIndex && !state.completedIndices.contains(index) {
            Capsule()
                .stroke(Theme.Color.sage.opacity(0.6), lineWidth: 2)
                .scaleEffect(1.05)
                .opacity(0.6)
        } else {
            EmptyView()
        }
    }

    private func pipColor(for index: Int) -> Color {
        if state.completedIndices.contains(index) { return Theme.Color.sage }
        if index == state.currentIndex { return Theme.Color.sage.opacity(0.55) }
        return Theme.Color.sage.opacity(0.18)
    }

    private var stepCard: some View {
        GlassCard(tone: .modal) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                stepHero
                stepBadge
                if let step = state.currentStep {
                    Text(step.instruction)
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let tip = step.tip {
                        tipCard(tip)
                    }
                }
            }
        }
        .shadow(Theme.Shadow.modal)
    }

    /// Visual anchor at the top of each step card. Shows the recipe's hero art when
    /// a local asset is bundled, otherwise falls back to the brewing mascot so every
    /// step has a warm focal point rather than bare text.
    @ViewBuilder
    private var stepHero: some View {
        if let heroImage = RecipeImageLookup.image(for: recipe) {
            heroImage
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Color.sage.opacity(0.15))
                .frame(height: 140)
                .overlay(MascotBadge(.brewing, size: 96))
        }
    }

    private var stepBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text("\(state.currentIndex + 1) / \(recipe.steps.count)")
                .font(Theme.Font.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.bone)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Theme.Color.forest, in: .capsule)
            Spacer(minLength: 0)
            if state.isCurrentStepTimed {
                Label("Timer", systemImage: Theme.Icon.timer)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.amber)
            }
        }
    }

    private func tipCard(_ tip: String) -> some View {
        GlassCard(tone: .subtle) {
            HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.Color.amber)
                Text(tip)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var timerArea: some View {
        if state.isCurrentStepTimed, let timer = state.timerModel {
            VStack(spacing: Theme.Spacing.md) {
                RingMetric(
                    value: Double(timer.totalSeconds - timer.remainingSeconds),
                    total: Double(timer.totalSeconds),
                    label: timer.formatted,
                    color: timer.state == .completed ? Theme.Color.sage : Theme.Color.forest
                )
                .frame(width: 160, height: 160)

                HStack(spacing: Theme.Spacing.sm) {
                    timerStartPauseButton(timer: timer)
                    PrimaryButton("Reset", variant: .ghost) {
                        RecipeHaptics.tick()
                        Task { @MainActor in state.resetTimer() }
                    }
                    .frame(maxWidth: 120)
                }

                // Always-available skip. Lets the user move on without finishing the
                // timer — useful when they've already hit the time elsewhere or just
                // want to jump ahead. Matches the "Duolingo-style but not punitive"
                // brief: gentle gating, not hard-locked.
                PrimaryButton(
                    state.isAtLastStep ? "Finish brew" : "Next step →",
                    variant: .ghost
                ) {
                    RecipeHaptics.tick()
                    Task { @MainActor in _ = state.advance() }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .glass(.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .shadow(Theme.Shadow.card)
        } else {
            HStack {
                PrimaryButton(state.isAtLastStep ? "Finish brew" : "Next step") {
                    RecipeHaptics.start()
                    Task { @MainActor in _ = state.advance() }
                }
                PrimaryButton("Back", variant: .ghost) {
                    RecipeHaptics.tick()
                    Task { @MainActor in state.goBack() }
                }
                .frame(maxWidth: 140)
            }
        }
    }

    @ViewBuilder
    private func timerStartPauseButton(timer: RecipeTimerModel) -> some View {
        switch timer.state {
        case .idle, .paused:
            PrimaryButton("Start") {
                RecipeHaptics.start()
                Task { @MainActor in state.startTimer() }
            }
        case .running:
            PrimaryButton("Pause", variant: .ghost) {
                RecipeHaptics.tick()
                Task { @MainActor in state.pauseTimer() }
            }
        case .completed:
            PrimaryButton(state.isAtLastStep ? "Finish brew" : "Next step") {
                RecipeHaptics.finish()
                Task { @MainActor in _ = state.advance() }
            }
        }
    }

    // MARK: - Overlays

    private func boundaryChipView(_ text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Color.sage)
                Text(text)
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glass(.capsule)
            .shadow(Theme.Shadow.float)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func snackbarView(_ text: String) -> some View {
        VStack {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: Theme.Icon.timer)
                    .foregroundStyle(Theme.Color.amber)
                Text(text)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glass(.capsule)
            .shadow(Theme.Shadow.float)
            .padding(.top, Theme.Spacing.md)
            Spacer()
        }
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) else { return }
                if dx < -40 {
                    _ = state.advance()
                } else if dx > 40 {
                    state.goBack()
                }
            }
    }
}

#Preview("Tea — multi-step") {
    NavigationStack {
        RecipePlayerView(
            recipe: RecipePreviewFixtures.teas.first!,
            onFinish: { _ in },
            onClose: {}
        )
    }
}

#Preview("Tincture — long cure") {
    NavigationStack {
        RecipePlayerView(
            recipe: RecipePreviewFixtures.localTinctures[0],
            onFinish: { _ in },
            onClose: {}
        )
    }
}
