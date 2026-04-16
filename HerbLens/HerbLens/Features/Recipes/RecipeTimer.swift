import Foundation
import Observation

/// Parses `Recipe.steepOrCureTime` strings into live-timer minutes.
/// Teas return a minute count; tincture cures (weeks/days/hours) return nil.
nonisolated enum SteepDurationParser {
    static func minutes(from raw: String?) -> Int? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()

        // Reject week/day/hour scales — not a live-timer preparation.
        let rejectUnits = ["week", "day", "hour", "overnight"]
        if rejectUnits.contains(where: { lower.contains($0) }) {
            return nil
        }

        let scanner = Scanner(string: lower)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        guard let first = scanner.scanInt() else { return nil }

        // Range form: "5-7 minutes" → take the lower bound.
        _ = scanner.scanString("-").flatMap { _ in scanner.scanInt() }

        // Must either be bare digits or followed by a minute unit ("min", "minute").
        let remainder = lower[scanner.currentIndex...].trimmingCharacters(in: .whitespaces)
        if remainder.isEmpty {
            return first
        }
        if remainder.hasPrefix("min") {
            return first
        }
        return nil
    }
}

/// Countdown state machine for tea steep timers. Not a wall-clock stopwatch —
/// decrements once per second while running, pauses on user action, raises
/// haptics at minute boundaries and the finish.
@Observable
@MainActor
final class RecipeTimerModel {
    enum State: Sendable, Hashable {
        case idle
        case running
        case paused
        case completed
    }

    let totalSeconds: Int
    private(set) var remainingSeconds: Int
    private(set) var state: State
    private var tickTask: Task<Void, Never>?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var formatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(totalMinutes: Int) {
        let clamped = max(1, totalMinutes)
        let total = clamped * 60
        self.totalSeconds = total
        self.remainingSeconds = total
        self.state = .idle
    }

    func start() {
        guard state != .running, state != .completed else { return }
        state = .running
        tickTask?.cancel()
        tickTask = Task { @MainActor [weak self] in
            while let self, self.state == .running, self.remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                guard self.state == .running else { return }
                self.tick()
            }
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        tickTask?.cancel()
    }

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        remainingSeconds = totalSeconds
        state = .idle
    }

    private func tick() {
        guard state == .running else { return }
        remainingSeconds = max(0, remainingSeconds - 1)
        if remainingSeconds == 0 {
            state = .completed
            tickTask?.cancel()
            RecipeHaptics.finish()
        } else if remainingSeconds % 60 == 0 {
            RecipeHaptics.tick()
        }
    }
}
