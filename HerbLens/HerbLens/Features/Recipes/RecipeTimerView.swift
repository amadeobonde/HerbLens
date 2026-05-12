import SwiftUI

/// Standalone live countdown, retained for contexts (previews, future ad-hoc
/// placements) that want a timer outside the Duolingo player. The player
/// itself draws the timer inline via `RingMetric` + `PrimaryButton`. Rendered
/// inside a `GlassCard(.standard)` with design-system motion/shadow tokens.
struct RecipeTimerView: View {
    @State private var model: RecipeTimerModel

    init(totalMinutes: Int) {
        _model = State(initialValue: RecipeTimerModel(totalMinutes: totalMinutes))
    }

    var body: some View {
        GlassCard(tone: .standard) {
            VStack(spacing: Theme.Spacing.md) {
                RingMetric(
                    value: Double(model.totalSeconds - model.remainingSeconds),
                    total: Double(model.totalSeconds),
                    label: model.formatted,
                    color: model.state == .completed ? Theme.Color.sage : Theme.Color.forest
                )
                .frame(width: 140, height: 140)

                Text(label)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                HStack(spacing: Theme.Spacing.sm) {
                    controlButton
                    PrimaryButton("Reset", variant: .ghost) {
                        RecipeHaptics.tick()
                        Task { @MainActor in model.reset() }
                    }
                    .frame(maxWidth: 140)
                }
            }
        }
        .shadow(Theme.Shadow.card)
    }

    private var label: String {
        switch model.state {
        case .idle: "Ready"
        case .running: "Steeping"
        case .paused: "Paused"
        case .completed: "Done"
        }
    }

    @ViewBuilder private var controlButton: some View {
        switch model.state {
        case .idle, .paused:
            PrimaryButton("Start") {
                RecipeHaptics.start()
                Task { @MainActor in model.start() }
            }
        case .running:
            PrimaryButton("Pause", variant: .ghost) {
                RecipeHaptics.tick()
                Task { @MainActor in model.pause() }
            }
        case .completed:
            PrimaryButton("Again") {
                RecipeHaptics.finish()
                Task { @MainActor in model.reset() }
            }
        }
    }
}

#Preview {
    RecipeTimerView(totalMinutes: 5)
        .padding()
        .background(Theme.Color.bone)
}
