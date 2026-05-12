import SwiftUI

public struct MascotBadge: View {
    public nonisolated enum Variant: String, Sendable, Hashable, CaseIterable {
        case `default`    = "Bamboo/Default"
        case scanning     = "Bamboo/Scanning"
        case celebrating  = "Bamboo/Celebrating"
        case brewing      = "Bamboo/Brewing"
        case sleeping     = "Bamboo/Sleeping"
        case teacher      = "Bamboo/Teacher"
        case thinking     = "Bamboo/Thinking"
        case confused     = "Bamboo/Confused"
    }

    private nonisolated let variant: Variant
    private nonisolated let size: CGFloat
    private nonisolated let breathes: Bool
    private nonisolated let behavior: MascotBehavior

    @State private var didAppear = false
    @State private var tapped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public nonisolated init(
        _ variant: Variant,
        size: CGFloat = 120,
        breathes: Bool = true,
        behavior: MascotBehavior = .idle
    ) {
        self.variant = variant
        self.size = size
        self.breathes = breathes
        self.behavior = behavior
    }

    public var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: size, maxHeight: size)
            .overlay {
                GeometryReader { geo in
                    let dim = min(geo.size.width, geo.size.height)
                    ZStack {
                        halo(dim: dim)
                        animatedMascot(dim: dim)
                    }
                    .frame(width: dim, height: dim)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .scaleEffect(didAppear ? 1.0 : 0.7)
            .opacity(didAppear ? 1.0 : 0.0)
            .animation(Theme.Motion.bounce, value: didAppear)
            .onAppear { didAppear = true }
            .onTapGesture {
                guard size >= 64, !reduceMotion else { return }
                tapped.toggle()
            }
    }

    // MARK: - Halo

    @ViewBuilder
    private func halo(dim: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.Color.sage.opacity(0.18),
                        Theme.Color.sage.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: dim * 0.55
                )
            )
            .frame(width: dim * 1.25, height: dim * 1.25)
    }

    // MARK: - Animated mascot image

    @ViewBuilder
    private func animatedMascot(dim: CGFloat) -> some View {
        let base = Image(variant.rawValue)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: dim, height: dim)

        if reduceMotion || !breathes {
            base.rotationEffect(.degrees(restingRotation))
        } else if dim < 40 {
            base
                .modifier(BreathingOnly())
                .rotationEffect(.degrees(restingRotation))
        } else {
            base.modifier(
                BehaviorAnimator(
                    behavior: behavior,
                    restingRotation: restingRotation,
                    tapped: tapped
                )
            )
        }
    }

    private var restingRotation: Double {
        switch variant {
        case .scanning:  -4
        case .celebrating: -2
        case .sleeping:  6
        case .brewing:   1
        case .confused:  -6
        case .thinking:  3
        default: 0
        }
    }
}

// MARK: - Breathing-only modifier (for small sizes)

private struct BreathingOnly: ViewModifier {
    @State private var breatheIn = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(breatheIn ? 1.04 : 1.0)
            .animation(
                .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: breatheIn
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    breatheIn = true
                }
            }
    }
}

// MARK: - Behavior animator

private struct BehaviorAnimator: ViewModifier {
    let behavior: MascotBehavior
    let restingRotation: Double
    let tapped: Bool

    @State private var tapBounce = false

    func body(content: Content) -> some View {
        switch behavior {
        case .idle:       content.modifier(IdleAnimator(restingRotation: restingRotation, tapped: tapped))
        case .working:    content.modifier(PhaseLoop<WorkingPhase>(restingRotation: restingRotation))
        case .celebrating: content.modifier(PhaseLoop<CelebratePhase>(restingRotation: restingRotation))
        case .sleepy:     content.modifier(PhaseLoop<SleepyPhase>(restingRotation: restingRotation))
        case .waving:     content.modifier(PhaseLoop<WavingPhase>(restingRotation: restingRotation))
        case .sipping:    content.modifier(PhaseLoop<SippingPhase>(restingRotation: restingRotation))
        case .attentive:  content.modifier(PhaseLoop<AttentivePhase>(restingRotation: restingRotation))
        case .lookAround: content.modifier(PhaseLoop<LookAroundPhase>(restingRotation: restingRotation))
        }
    }
}

// MARK: - Idle animator with random fidgets

private struct IdleAnimator: ViewModifier {
    let restingRotation: Double
    let tapped: Bool

    @State private var fidgetIndex = 0
    @State private var timer: Timer?

    private static let fidgetSequences: [[MascotPose]] = [
        // Glance left-right
        [MascotPose(rotation: -6, offsetY: -1), MascotPose(rotation: 6, offsetY: -1), .rest],
        // Weight shift
        [MascotPose(scale: 1.02, offsetY: -3), .rest],
        // Blink squash
        [MascotPose(scaleY: 0.96), .rest],
        // Settle bounce
        [MascotPose(scale: 1.06, offsetY: -4), MascotPose(scale: 0.98, offsetY: 1), .rest],
        // Ear wiggle (rapid small rotations)
        [MascotPose(rotation: 3), MascotPose(rotation: -3), MascotPose(rotation: 2), .rest],
    ]

    func body(content: Content) -> some View {
        PhaseAnimator(IdlePhase.allCases, trigger: fidgetIndex) { phase in
            let pose = fidgetPose(for: phase)
            content
                .scaleEffect(x: pose.scale, y: pose.scale * pose.scaleY)
                .rotationEffect(.degrees(pose.rotation + restingRotation))
                .offset(y: pose.offsetY)
                .scaleEffect(tapped ? 1.12 : 1.0)
                .rotationEffect(tapped ? .degrees(-8) : .zero)
        } animation: { phase in
            if tapped { return Theme.Motion.bounce }
            return phase.animation
        }
        .animation(Theme.Motion.bounce, value: tapped)
        .onAppear { startFidgetTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func fidgetPose(for phase: IdlePhase) -> MascotPose {
        switch phase {
        case .fidget:
            let seq = Self.fidgetSequences[abs(fidgetIndex) % Self.fidgetSequences.count]
            return seq.first ?? .rest
        default:
            return phase.pose
        }
    }

    private func startFidgetTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0 + Double.random(in: 0...3), repeats: true) { _ in
            Task { @MainActor in
                fidgetIndex += 1
            }
        }
    }
}

// MARK: - Generic phase loop

private protocol PhaseBehavior: CaseIterable, Sendable where AllCases: RandomAccessCollection {
    var pose: MascotPose { get }
    var animation: Animation { get }
}

extension WorkingPhase: PhaseBehavior {}
extension CelebratePhase: PhaseBehavior {}
extension SleepyPhase: PhaseBehavior {}
extension WavingPhase: PhaseBehavior {}
extension SippingPhase: PhaseBehavior {}
extension AttentivePhase: PhaseBehavior {}
extension LookAroundPhase: PhaseBehavior {}

private struct PhaseLoop<P: PhaseBehavior>: ViewModifier where P: Equatable {
    let restingRotation: Double

    func body(content: Content) -> some View {
        PhaseAnimator(P.allCases) { phase in
            let pose = phase.pose
            content
                .scaleEffect(x: pose.scale, y: pose.scale * pose.scaleY)
                .rotationEffect(.degrees(pose.rotation + restingRotation))
                .offset(y: pose.offsetY)
        } animation: { phase in
            phase.animation
        }
    }
}

// MARK: - Preview

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

            Divider()

            Text("Behaviors").font(Theme.Font.headline)

            MascotBadge(.default, size: 140, behavior: .waving)
            Text("Waving").font(Theme.Font.caption)

            MascotBadge(.celebrating, size: 140, behavior: .celebrating)
            Text("Celebrating").font(Theme.Font.caption)

            MascotBadge(.brewing, size: 140, behavior: .sipping)
            Text("Sipping").font(Theme.Font.caption)

            MascotBadge(.scanning, size: 140, behavior: .working)
            Text("Working").font(Theme.Font.caption)

            MascotBadge(.sleeping, size: 140, behavior: .sleepy)
            Text("Sleepy").font(Theme.Font.caption)

            MascotBadge(.teacher, size: 140, behavior: .attentive)
            Text("Attentive").font(Theme.Font.caption)

            MascotBadge(.default, size: 140, behavior: .lookAround)
            Text("Look Around").font(Theme.Font.caption)
        }
        .padding()
    }
    .background(Theme.Color.background)
}
