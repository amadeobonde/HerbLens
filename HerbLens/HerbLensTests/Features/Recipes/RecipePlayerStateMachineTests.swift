import Foundation
import Testing
@testable import HerbLens

/// State-machine tests for `RecipePlayerState`. Asserts swipe-advance gating
/// (timed steps must complete before advance) and that timer-required steps
/// emit the expected event sequence (`.advanceBlocked` snackbar → timer
/// completion → `.advanced`).
@Suite("RecipePlayerState")
@MainActor
struct RecipePlayerStateMachineTests {
    private func untimed(_ index: Int, _ text: String) -> RecipeStep {
        RecipeStep(stepNumber: index, instruction: text, tip: nil)
    }

    private func timed(_ index: Int, _ minutes: Int, _ tip: String? = nil) -> RecipeStep {
        // Phrasing matches `RecipeStepDuration.minutes(for:)` recogniser.
        RecipeStep(stepNumber: index, instruction: "Steep for \(minutes) minutes.", tip: tip)
    }

    // MARK: - Step duration parser

    @Test("untimed step has no duration")
    func untimedStepHasNoDuration() {
        let step = untimed(1, "Add 1 cup of water and stir.")
        #expect(RecipeStepDuration.minutes(for: step) == nil)
    }

    @Test("timed step parses minutes from instruction")
    func timedStepDuration() {
        #expect(RecipeStepDuration.minutes(for: timed(1, 5)) == 5)
        #expect(RecipeStepDuration.minutes(for: timed(2, 10)) == 10)
    }

    @Test("range form picks the lower bound")
    func rangeLowerBound() {
        let step = RecipeStep(stepNumber: 1, instruction: "Steep for 5-7 minutes.", tip: nil)
        #expect(RecipeStepDuration.minutes(for: step) == 5)
    }

    @Test("number without minute unit does not start a timer")
    func numberWithoutUnit() {
        let step = RecipeStep(stepNumber: 1, instruction: "Use 1 cup of water and 2 tsp honey.", tip: nil)
        #expect(RecipeStepDuration.minutes(for: step) == nil)
    }

    // MARK: - Initial state

    @Test("initial state enters step 0 and emits stepEntered event")
    func initialStateEnters() {
        let state = RecipePlayerState(steps: [untimed(1, "Boil water."), untimed(2, "Pour and serve.")])
        #expect(state.currentIndex == 0)
        #expect(state.events.contains(.stepEntered(index: 0)))
        #expect(state.canAdvance == true) // untimed step is auto-completable
    }

    @Test("first step is timed → cannot advance until timer completes")
    func timedFirstStepGatesAdvance() {
        let state = RecipePlayerState(steps: [timed(1, 5), untimed(2, "Pour.")])
        #expect(state.canAdvance == false)
        #expect(state.isCurrentStepTimed == true)
    }

    // MARK: - Swipe-advance gating

    @Test("advance on untimed step succeeds")
    func advanceOnUntimedSucceeds() {
        let state = RecipePlayerState(steps: [
            untimed(1, "Boil water."),
            untimed(2, "Pour and serve."),
        ])
        let result = state.advance()
        #expect(result == .advanced)
        #expect(state.currentIndex == 1)
        #expect(state.events.contains(.stepCompleted(index: 0)))
        #expect(state.events.contains(.stepEntered(index: 1)))
    }

    @Test("advance on uncompleted timed step is blocked + emits snackbar")
    func advanceBlockedByTimer() {
        let state = RecipePlayerState(steps: [timed(1, 5), untimed(2, "Pour.")])
        let result = state.advance()
        #expect(result == .blockedByTimer)
        #expect(state.currentIndex == 0) // did not move
        #expect(state.snackbar == "Wait for the timer")
        #expect(state.events.contains(.advanceBlocked(index: 0)))
    }

    @Test("clearing the snackbar resets it")
    func clearSnackbar() {
        let state = RecipePlayerState(steps: [timed(1, 5)])
        _ = state.advance()
        #expect(state.snackbar != nil)
        state.clearSnackbar()
        #expect(state.snackbar == nil)
    }

    @Test("timer completion unblocks advance")
    func timerCompletionUnblocks() {
        let state = RecipePlayerState(steps: [timed(1, 5), untimed(2, "Pour.")])
        #expect(state.canAdvance == false)
        // Simulate the timer reaching zero — the view layer calls this when its
        // bound `RecipeTimerModel.state` flips to `.completed`.
        state.handleTimerCompletion()
        #expect(state.canAdvance == true)
        let result = state.advance()
        #expect(result == .advanced)
        #expect(state.currentIndex == 1)
        #expect(state.events.contains(.timerCompleted(index: 0)))
    }

    @Test("resetting the timer re-blocks advance")
    func resetTimerReblocks() {
        let state = RecipePlayerState(steps: [timed(1, 5), untimed(2, "Pour.")])
        state.handleTimerCompletion()
        #expect(state.canAdvance == true)
        state.resetTimer()
        #expect(state.canAdvance == false)
    }

    // MARK: - Boundaries

    @Test("advancing past the last step finishes")
    func advancePastLastStep() {
        let state = RecipePlayerState(steps: [
            untimed(1, "Boil water."),
            untimed(2, "Pour and serve."),
        ])
        _ = state.advance() // index 0 → 1
        let result = state.advance() // index 1 → finished
        #expect(result == .finished)
        #expect(state.didReachEnd == true)
        #expect(state.events.contains(.finished))
    }

    @Test("goBack from index 0 is a no-op")
    func goBackFromStart() {
        let state = RecipePlayerState(steps: [untimed(1, "Boil water.")])
        state.goBack()
        #expect(state.currentIndex == 0)
    }

    @Test("goBack returns to previous step")
    func goBackToPrevious() {
        let state = RecipePlayerState(steps: [
            untimed(1, "Boil water."),
            untimed(2, "Pour and serve."),
        ])
        _ = state.advance()
        #expect(state.currentIndex == 1)
        state.goBack()
        #expect(state.currentIndex == 0)
    }

    // MARK: - Boundary chip

    @Test("advancing emits the boundary chip")
    func boundaryChipOnAdvance() {
        let state = RecipePlayerState(steps: [
            untimed(1, "Boil water."),
            untimed(2, "Pour and serve."),
        ])
        _ = state.advance()
        #expect(state.boundaryChip == "Step 1 of 2 \u{2713}")
        state.clearBoundaryChip()
        #expect(state.boundaryChip == nil)
    }

    // MARK: - Mixed sequence

    @Test("mixed timed + untimed steps gate per-step independently")
    func mixedSequence() {
        let state = RecipePlayerState(steps: [
            timed(1, 3),                    // gated
            untimed(2, "Strain."),          // free
            timed(3, 2),                    // gated
            untimed(4, "Serve hot."),       // free
        ])

        // Step 0: blocked until timer completion.
        #expect(state.advance() == .blockedByTimer)
        state.handleTimerCompletion()
        #expect(state.advance() == .advanced)
        #expect(state.currentIndex == 1)

        // Step 1: untimed → advance immediately.
        #expect(state.advance() == .advanced)
        #expect(state.currentIndex == 2)

        // Step 2: timed again → blocked.
        #expect(state.advance() == .blockedByTimer)
        state.handleTimerCompletion()
        #expect(state.advance() == .advanced)
        #expect(state.currentIndex == 3)

        // Step 3: untimed and last → finishes.
        #expect(state.advance() == .finished)
        #expect(state.didReachEnd == true)
    }
}
