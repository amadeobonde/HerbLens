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
    /// When true, the mascot gently breathes (subtle scale pulse) forever. On
    /// by default — makes every surface where a mascot sits feel alive rather
    /// than frozen. Turn off for static list cells / tiny avatars.
    private nonisolated let breathes: Bool

    @State private var didAppear = false
    @State private var breatheIn = false

    public nonisolated init(_ variant: Variant, size: CGFloat = 120, breathes: Bool = true) {
        self.variant = variant
        self.size = size
        self.breathes = breathes
    }

    public var body: some View {
        ZStack {
            // Soft radial halo — pulses in sync with the mascot's breath.
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
                .scaleEffect(breathes && breatheIn ? 1.08 : 1.0)
                .opacity(breathes && breatheIn ? 1.0 : 0.85)

            Image(variant.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                // Idle breathing — tiny 4% scale pulse forever. Variant-specific
                // rotations fire per-use-site (e.g. scanning spins on Scan loading,
                // celebrating jumps a notch on Scan result).
                .scaleEffect(breathes && breatheIn ? 1.04 : 1.0)
                .rotationEffect(.degrees(variantIdleRotation))
        }
        .scaleEffect(didAppear ? 1.0 : 0.7)
        .opacity(didAppear ? 1.0 : 0.0)
        .animation(Theme.Motion.bounce, value: didAppear)
        .animation(
            .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
            value: breatheIn
        )
        .onAppear {
            didAppear = true
            if breathes {
                // Small stagger so mascots on the same screen don't all pulse
                // in lockstep. Uses the variant enum's hash as a cheap per-instance offset.
                let delay = Double(abs(variant.hashValue) % 100) / 100.0 * 0.8
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    breatheIn = true
                }
            }
        }
    }

    /// Variant-specific idle pose rotation — subtle, not a full animation. Scanning
    /// Bamboo tilts slightly toward the magnifying glass; celebrating tilts upward;
    /// sleeping leans. Keeps each mascot pose expressive even while static.
    private var variantIdleRotation: Double {
        switch variant {
        case .scanning: return -4
        case .celebrating: return -2
        case .sleeping: return 6
        case .brewing: return 1
        default: return 0
        }
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
