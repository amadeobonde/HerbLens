import SwiftUI
import UIKit

/// Loading screen shown while the identify-plant edge fn runs. Bamboo wobbles gently
/// (~8° period 2s) while rotating status copy turns the ~2-3 s wait into a guided
/// moment. Uses the blurred captured photo as a bespoke backdrop when available.
struct ScanLoadingView: View {
    private static let copy: [String] = [
        "Looking at the leaves…",
        "Checking the petals…",
        "Comparing to known herbs…"
    ]

    let capturedImage: UIImage?

    @State private var copyIndex: Int = 0

    init(capturedImage: UIImage? = nil) {
        self.capturedImage = capturedImage
    }

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                MascotBadge(.scanning, size: 180, behavior: .working)

                GlassCard(tone: .subtle) {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(Self.copy[copyIndex])
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .id(copyIndex)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("Hang tight — Bamboo is on it.")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.xl)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                if Task.isCancelled { break }
                withAnimation(Theme.Motion.gentle) {
                    copyIndex = (copyIndex + 1) % Self.copy.count
                }
            }
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let capturedImage {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFill()
                .blur(radius: 32)
                .overlay(Theme.Color.background.opacity(0.55))
        } else {
            Theme.Color.background
        }
    }
}

#Preview { ScanLoadingView() }
