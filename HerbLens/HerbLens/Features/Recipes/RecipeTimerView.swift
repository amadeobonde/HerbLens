import SwiftUI

/// Live countdown surfaced inside `RecipeDetailView` whenever a tea's
/// `steepOrCureTime` parses to a live-timer minute count. Tincture cures
/// (weeks/days) never reach this view.
struct RecipeTimerView: View {
    @State private var model: RecipeTimerModel

    init(totalMinutes: Int) {
        _model = State(initialValue: RecipeTimerModel(totalMinutes: totalMinutes))
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Theme.Color.sage.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: model.progress)
                    .stroke(Theme.Color.forest, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: model.progress)
                VStack(spacing: 2) {
                    Text(model.formatted)
                        .font(Theme.Font.captionMono)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Color.textPrimary)
                        .font(.system(size: 28, weight: .regular, design: .monospaced))
                    Text(label)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .frame(width: 120, height: 120)

            HStack(spacing: Theme.Spacing.md) {
                controlButton
                Button(action: model.reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .tint(Theme.Color.forest)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glass(.card)
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
            Button(action: {
                RecipeHaptics.start()
                model.start()
            }) {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Color.forest)
        case .running:
            Button(action: model.pause) {
                Label("Pause", systemImage: "pause.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Color.amber)
        case .completed:
            Button(action: model.reset) {
                Label("Again", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Color.sage)
        }
    }
}

#Preview {
    RecipeTimerView(totalMinutes: 5)
        .padding()
        .background(Theme.Color.bone)
}
