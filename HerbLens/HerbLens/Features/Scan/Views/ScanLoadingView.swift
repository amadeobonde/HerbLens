import SwiftUI

/// Bamboo with the magnifying glass pulses while the edge fn runs. Rotating progress
/// copy turns the ~2-3 s wait into a guided moment instead of an unknown stall.
struct ScanLoadingView: View {
    private static let copy: [String] = [
        "Studying the leaves…",
        "Checking the botanicals…",
        "Cross-referencing health notes…",
    ]

    @State private var pulse: Bool = false
    @State private var copyIndex: Int = 0

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image("Scan/BambooScanning")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse ? 1.0 : 0.92)
                    .opacity(pulse ? 1.0 : 0.85)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulse
                    )

                Text(Self.copy[copyIndex])
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .id(copyIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                Text("Hang tight — Bamboo is on it.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Spacing.xl)
        }
        .task {
            pulse = true
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Task.isCancelled { break }
                withAnimation(.easeInOut) {
                    copyIndex = (copyIndex + 1) % Self.copy.count
                }
            }
        }
    }
}

#Preview { ScanLoadingView() }
