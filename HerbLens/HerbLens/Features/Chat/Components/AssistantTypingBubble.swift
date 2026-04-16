import SwiftUI

/// Three-dot indicator shown while waiting for the first token of an assistant reply.
/// Dots stagger their opacity so the pill feels alive without being noisy.
struct AssistantTypingBubble: View {
    @State private var tick: Int = 0
    private let dotCount = 3

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
            BambooAvatarView(size: 28)
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(Theme.Color.forest)
                        .frame(width: 6, height: 6)
                        .opacity(opacity(for: index))
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .glass(.capsule)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 180_000_000)
                tick = (tick + 1) % dotCount
            }
        }
        .accessibilityLabel("Bamboo is typing")
    }

    private func opacity(for index: Int) -> Double {
        index == tick ? 1.0 : 0.35
    }
}

#Preview {
    AssistantTypingBubble()
        .padding(Theme.Spacing.lg)
        .background(Theme.Color.background)
}
