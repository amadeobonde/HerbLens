import SwiftUI

public nonisolated enum MascotBehavior: Sendable, Hashable {
    case idle
    case working
    case celebrating
    case sleepy
    case waving
    case sipping
    case attentive
    case lookAround
}

// MARK: - Phase definitions

nonisolated struct MascotPose: Equatable {
    var scale: CGFloat = 1.0
    var scaleY: CGFloat = 1.0
    var rotation: Double = 0
    var offsetY: CGFloat = 0

    static let rest = MascotPose()
}

nonisolated enum IdlePhase: CaseIterable, Sendable {
    case breatheIn
    case breatheOut
    case fidget
    case settle

    var pose: MascotPose {
        switch self {
        case .breatheIn:  MascotPose(scale: 1.04)
        case .breatheOut: .rest
        case .fidget:     MascotPose(scale: 1.02, rotation: -5, offsetY: -2)
        case .settle:     .rest
        }
    }

    var duration: Double {
        switch self {
        case .breatheIn:  1.2
        case .breatheOut: 1.2
        case .fidget:     0.6
        case .settle:     0.8
        }
    }

    var animation: Animation {
        switch self {
        case .breatheIn, .breatheOut: .easeInOut(duration: duration)
        case .fidget: Theme.Motion.fidget
        case .settle: Theme.Motion.gentle
        }
    }
}

nonisolated enum WorkingPhase: CaseIterable, Sendable {
    case up, down

    var pose: MascotPose {
        switch self {
        case .up:   MascotPose(scale: 1.02, rotation: -2, offsetY: -4)
        case .down: MascotPose(rotation: 2)
        }
    }

    var animation: Animation { .easeInOut(duration: 0.75) }
}

nonisolated enum CelebratePhase: CaseIterable, Sendable {
    case launch, peak, squash, settle

    var pose: MascotPose {
        switch self {
        case .launch:  MascotPose(scale: 0.92, scaleY: 0.92, offsetY: 2)
        case .peak:    MascotPose(scale: 1.15, rotation: -8, offsetY: -12)
        case .squash:  MascotPose(scale: 0.95, scaleY: 0.95, rotation: 8)
        case .settle:  .rest
        }
    }

    var animation: Animation {
        switch self {
        case .launch: Theme.Motion.micro
        case .peak:   Theme.Motion.celebrate
        case .squash: Theme.Motion.fidget
        case .settle: Theme.Motion.bounce
        }
    }
}

nonisolated enum SleepyPhase: CaseIterable, Sendable {
    case driftLeft, center, driftRight, back

    var pose: MascotPose {
        switch self {
        case .driftLeft:  MascotPose(scale: 1.02, rotation: 4, offsetY: 2)
        case .center:     MascotPose(scale: 1.0)
        case .driftRight: MascotPose(scale: 1.02, rotation: -2, offsetY: 1)
        case .back:       MascotPose(scale: 1.0)
        }
    }

    var animation: Animation { .easeInOut(duration: 1.6) }
}

nonisolated enum WavingPhase: CaseIterable, Sendable {
    case windUp, waveOut, waveBack, settle

    var pose: MascotPose {
        switch self {
        case .windUp:   MascotPose(scale: 0.95, rotation: 8, offsetY: 2)
        case .waveOut:  MascotPose(scale: 1.08, rotation: -12, offsetY: -6)
        case .waveBack: MascotPose(scale: 1.03, rotation: 6, offsetY: -2)
        case .settle:   .rest
        }
    }

    var animation: Animation {
        switch self {
        case .windUp:  Theme.Motion.fidget
        case .waveOut: Theme.Motion.bounce
        case .waveBack: Theme.Motion.fidget
        case .settle:  Theme.Motion.gentle
        }
    }
}

nonisolated enum SippingPhase: CaseIterable, Sendable {
    case leanIn, sip, leanBack, savor

    var pose: MascotPose {
        switch self {
        case .leanIn:   MascotPose(rotation: 12, offsetY: 3)
        case .sip:      MascotPose(scale: 1.03, rotation: 14, offsetY: 2)
        case .leanBack: MascotPose(scale: 1.02, rotation: -3, offsetY: -2)
        case .savor:    .rest
        }
    }

    var animation: Animation {
        switch self {
        case .leanIn:  .easeInOut(duration: 0.6)
        case .sip:     .easeInOut(duration: 0.8)
        case .leanBack: Theme.Motion.bounce
        case .savor:   .easeInOut(duration: 0.6)
        }
    }
}

nonisolated enum AttentivePhase: CaseIterable, Sendable {
    case leanForward, hold, ease

    var pose: MascotPose {
        switch self {
        case .leanForward: MascotPose(scale: 1.03, rotation: -3, offsetY: -2)
        case .hold:        MascotPose(scale: 1.04, rotation: -3, offsetY: -2)
        case .ease:        MascotPose(scale: 1.01, rotation: -1)
        }
    }

    var animation: Animation {
        switch self {
        case .leanForward: Theme.Motion.gentle
        case .hold: .easeInOut(duration: 1.2)
        case .ease: .easeInOut(duration: 1.0)
        }
    }
}

nonisolated enum LookAroundPhase: CaseIterable, Sendable {
    case glanceLeft, pause, glanceRight, center

    var pose: MascotPose {
        switch self {
        case .glanceLeft:  MascotPose(rotation: -8, offsetY: -1)
        case .pause:       MascotPose(rotation: -6)
        case .glanceRight: MascotPose(rotation: 8, offsetY: -1)
        case .center:      .rest
        }
    }

    var animation: Animation {
        switch self {
        case .glanceLeft:  Theme.Motion.fidget
        case .pause:       .easeInOut(duration: 1.0)
        case .glanceRight: Theme.Motion.fidget
        case .center:      Theme.Motion.gentle
        }
    }
}
