import Foundation
import Testing
@testable import HerbLens

@Suite("Steep duration parsing")
struct SteepDurationParserTests {
    @Test("lower bound of a range wins", arguments: [
        ("5-7 minutes", 5),
        ("10-15 minutes", 10),
        ("3-5 min", 3),
    ])
    func lowerBoundOfRange(raw: String, expected: Int) {
        #expect(SteepDurationParser.minutes(from: raw) == expected)
    }

    @Test("plain minute counts parse", arguments: [
        ("10 minutes", 10),
        ("5 min", 5),
        ("1 minute", 1),
        ("7", 7),
    ])
    func plainMinutes(raw: String, expected: Int) {
        #expect(SteepDurationParser.minutes(from: raw) == expected)
    }

    @Test("weeks/days/hours return nil (not a live timer)", arguments: [
        "4-6 weeks", "6 weeks", "2 days", "3 hours",
    ])
    func tinctureCuresReturnNil(raw: String) {
        #expect(SteepDurationParser.minutes(from: raw) == nil)
    }

    @Test("nil/empty input returns nil")
    func nilInput() {
        #expect(SteepDurationParser.minutes(from: nil) == nil)
        #expect(SteepDurationParser.minutes(from: "") == nil)
    }

    @Test("non-minute units without number return nil", arguments: [
        "weeks", "a long time", "overnight",
    ])
    func nonsenseReturnsNil(raw: String) {
        #expect(SteepDurationParser.minutes(from: raw) == nil)
    }
}

@Suite("RecipeTimerModel")
@MainActor
struct RecipeTimerModelTests {
    @Test("initial state is idle with full remaining")
    func initialState() {
        let model = RecipeTimerModel(totalMinutes: 5)
        #expect(model.state == .idle)
        #expect(model.remainingSeconds == 300)
        #expect(model.totalSeconds == 300)
        #expect(model.progress == 0)
        #expect(model.formatted == "5:00")
    }

    @Test("pause before start is a no-op")
    func pauseFromIdleNoOp() {
        let model = RecipeTimerModel(totalMinutes: 3)
        model.pause()
        #expect(model.state == .idle)
    }

    @Test("reset returns to full after any interaction")
    func resetRestoresFull() {
        let model = RecipeTimerModel(totalMinutes: 2)
        model.start()
        model.pause()
        model.reset()
        #expect(model.state == .idle)
        #expect(model.remainingSeconds == 120)
        #expect(model.progress == 0)
    }

    @Test("formatted string pads seconds")
    func formattingPad() {
        let model = RecipeTimerModel(totalMinutes: 1)
        #expect(model.formatted == "1:00")
    }

    @Test("clamps totalMinutes to at least 1")
    func clampsBelowOne() {
        let zero = RecipeTimerModel(totalMinutes: 0)
        #expect(zero.totalSeconds == 60)
        let negative = RecipeTimerModel(totalMinutes: -5)
        #expect(negative.totalSeconds == 60)
    }
}
