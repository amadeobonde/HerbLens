import Foundation

/// Per-step duration helper. A step is "timed" if its instruction text contains
/// a parseable minute count; otherwise it advances on swipe-tap with no gating.
nonisolated enum RecipeStepDuration {
    /// Returns the parsed minute count if the step's instruction contains a
    /// `SteepDurationParser`-recognised duration ("steep 5 minutes", "boil 3-5 min", etc.).
    /// Returns `nil` for instructions with no embedded timer (read-only steps).
    static func minutes(for step: RecipeStep) -> Int? {
        // Look for a "<number> minute(s)" or "<n>-<m> minute(s)" substring inside
        // the instruction text. We delegate to `SteepDurationParser` after locating
        // a likely timer phrase so a step that *mentions* a number (e.g. "Use 1 cup")
        // doesn't accidentally start a 1-minute timer.
        let instruction = step.instruction.lowercased()
        let triggers = ["minute", "minutes", " min", " min."]
        guard triggers.contains(where: { instruction.contains($0) }) else { return nil }

        // Walk every numeric run and try to parse it + tail as a duration phrase.
        let scanner = Scanner(string: instruction)
        scanner.charactersToBeSkipped = nil
        while !scanner.isAtEnd {
            // Skip non-digits.
            _ = scanner.scanCharacters(from: CharacterSet.decimalDigits.inverted)
            let start = scanner.currentIndex
            guard scanner.scanInt() != nil else { return nil }
            // Try parsing from this digit forward as a duration phrase.
            let candidate = String(instruction[start...])
            if let parsed = SteepDurationParser.minutes(from: candidate) {
                return parsed
            }
        }
        return nil
    }
}

/// Pure state machine driving `RecipePlayerView`. Owns the current step index,
/// the current step's countdown (if any), and a tiny event log so tests can
/// assert UI-visible reactions (snackbar, boundary chip) without touching SwiftUI.
@Observable
@MainActor
final class RecipePlayerState {
    enum AdvanceResult: Sendable, Hashable {
        /// Advance succeeded — `currentIndex` moved.
        case advanced
        /// Already at the last step — caller should present the finish flow.
        case finished
        /// Current step has a timer that hasn't completed yet — show a snackbar.
        case blockedByTimer
    }

    enum Event: Sendable, Hashable {
        case stepEntered(index: Int)
        case stepCompleted(index: Int)
        case timerStarted(index: Int)
        case timerCompleted(index: Int)
        case advanceBlocked(index: Int)
        case finished
    }

    let steps: [RecipeStep]
    private(set) var currentIndex: Int = 0
    /// Set of step indices that have been "completed" (timer finished or step
    /// has no timer and the user has visited it). Used both to gate forward
    /// advancement and to render the progress pips at the top of the player.
    private(set) var completedIndices: Set<Int> = []
    /// Most recent transient snackbar message ("Wait for the timer"). Cleared
    /// by the view layer after dwell time.
    private(set) var snackbar: String?
    /// Fires once when the player reaches the end + user advances. View layer
    /// presents `RecipeFinishView` when this flips to `true`.
    private(set) var didReachEnd: Bool = false
    /// Append-only event log for tests + analytics. Last entry is the most
    /// recent event.
    private(set) var events: [Event] = []
    /// Boundary-chip text ("Step 3 of 5 ✓"). Set on advance, cleared by the
    /// view after the chip's dwell animation.
    private(set) var boundaryChip: String?

    /// Active per-step timer model. Lives on the player so tests can poke it
    /// directly; the view binds to it via `playerState.timerModel`.
    private(set) var timerModel: RecipeTimerModel?

    init(steps: [RecipeStep]) {
        self.steps = steps
        if let first = steps.first {
            spinUpTimer(for: 0)
            events.append(.stepEntered(index: 0))
            // Untimed steps are completable on entry — the user just reads + swipes.
            if RecipeStepDuration.minutes(for: first) == nil {
                completedIndices.insert(0)
            }
        }
    }

    var currentStep: RecipeStep? {
        guard steps.indices.contains(currentIndex) else { return nil }
        return steps[currentIndex]
    }

    var isCurrentStepTimed: Bool {
        guard let step = currentStep else { return false }
        return RecipeStepDuration.minutes(for: step) != nil
    }

    /// `true` if the current step's gating (timer, etc.) has been satisfied.
    var canAdvance: Bool {
        completedIndices.contains(currentIndex)
    }

    var isAtLastStep: Bool {
        currentIndex == steps.count - 1
    }

    // MARK: - Intents

    @discardableResult
    func advance() -> AdvanceResult {
        guard canAdvance else {
            snackbar = "Wait for the timer"
            events.append(.advanceBlocked(index: currentIndex))
            return .blockedByTimer
        }
        events.append(.stepCompleted(index: currentIndex))

        if isAtLastStep {
            didReachEnd = true
            events.append(.finished)
            return .finished
        }

        let next = currentIndex + 1
        boundaryChip = "Step \(currentIndex + 1) of \(steps.count) \u{2713}"
        currentIndex = next
        spinUpTimer(for: next)
        events.append(.stepEntered(index: next))
        if let step = currentStep, RecipeStepDuration.minutes(for: step) == nil {
            completedIndices.insert(next)
        }
        return .advanced
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        spinUpTimer(for: currentIndex)
        events.append(.stepEntered(index: currentIndex))
    }

    func startTimer() {
        guard let timer = timerModel else { return }
        timer.start()
        events.append(.timerStarted(index: currentIndex))
    }

    func pauseTimer() {
        timerModel?.pause()
    }

    func resetTimer() {
        timerModel?.reset()
        completedIndices.remove(currentIndex)
    }

    /// Called by the view layer when the bound timer reports `.completed`.
    /// Marks the step complete, advances `completedIndices`, and emits an event.
    func handleTimerCompletion() {
        guard isCurrentStepTimed, !completedIndices.contains(currentIndex) else { return }
        completedIndices.insert(currentIndex)
        events.append(.timerCompleted(index: currentIndex))
    }

    func clearSnackbar() {
        snackbar = nil
    }

    func clearBoundaryChip() {
        boundaryChip = nil
    }

    // MARK: - Internals

    private func spinUpTimer(for index: Int) {
        guard steps.indices.contains(index),
              let minutes = RecipeStepDuration.minutes(for: steps[index]) else {
            timerModel = nil
            return
        }
        timerModel = RecipeTimerModel(totalMinutes: minutes)
    }
}
