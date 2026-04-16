import SwiftUI

/// Three sage dots that pulse left-to-right while waiting for the first token of an
/// assistant reply. Animates with `Theme.Motion.gentle` to match the Scan loading dots.
struct AssistantTypingBubble: View {
    @State private var tick: Int = 0
    private let dotCount = 3

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.xs) {
            MascotBadge(.teacher, size: 28)
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(Theme.Color.sage)
                        .frame(width: 8, height: 8)
                        .scaleEffect(tick == index ? 1.25 : 0.85)
                        .opacity(tick == index ? 1.0 : 0.45)
                        .animation(Theme.Motion.gentle, value: tick)
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .glass(.capsule)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 240_000_000)
                tick = (tick + 1) % dotCount
            }
        }
        .accessibilityLabel("Bamboo is typing")
    }
}

#Preview {
    AssistantTypingBubble()
        .padding(Theme.Spacing.lg)
        .background(Theme.Color.background)
}
