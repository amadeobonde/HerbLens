import SwiftUI

/// Bamboo mascot image with a soft sage halo and a spring-in entrance animation.
/// Variant maps 1:1 to imagesets bundled under `Bamboo/` in the asset catalog.
public struct MascotBadge: View {
    public nonisolated enum Variant: String, Sendable, Hashable, CaseIterable {
        case `default`    = "Bamboo/Default"
        case scanning     = "Bamboo/Scanning"
        case celebrating  = "Bamboo/Celebrating"
        case brewing      = "Bamboo/Brewing"
        case sleeping     = "Bamboo/Sleeping"
        case teacher      = "Bamboo/Teacher"
    }

    private nonisolated let variant: Variant
    private nonisolated let size: CGFloat

    @State private var didAppear = false

    public nonisolated init(_ variant: Variant, size: CGFloat = 120) {
        self.variant = variant
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Soft radial halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Color.sage.opacity(0.18),
                            Theme.Color.sage.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.25, height: size * 1.25)

            Image(variant.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
        .scaleEffect(didAppear ? 1.0 : 0.7)
        .opacity(didAppear ? 1.0 : 0.0)
        .animation(Theme.Motion.bounce, value: didAppear)
        .onAppear { didAppear = true }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(MascotBadge.Variant.allCases, id: \.self) { variant in
                VStack(spacing: Theme.Spacing.xs) {
                    MascotBadge(variant, size: 140)
                    Text(variant.rawValue)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .padding()
    }
    .background(Theme.Color.background)
}
