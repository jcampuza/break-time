import XCTest
@testable import BreakTimeCore

final class AntiRsiReducerTests: XCTestCase {
    func testMiniBreakStartsAfterInterval() {
        let patch = AntiRsiConfigPatch(
            mini: BreakConfigPatch(intervalSeconds: 10, durationSeconds: 5),
            work: WorkBreakConfigPatch(intervalSeconds: 100, durationSeconds: 50, postponeSeconds: 10)
        )
        let state = createInitialState(configOverride: patch)

        let next = reduce(state: state, action: .tick(idleSeconds: 0, dtSeconds: 10))

        XCTAssertEqual(next.status, .inMini)
    }

    func testWorkBreakStartsAfterInterval() {
        let patch = AntiRsiConfigPatch(
            mini: BreakConfigPatch(intervalSeconds: 100, durationSeconds: 5),
            work: WorkBreakConfigPatch(intervalSeconds: 20, durationSeconds: 50, postponeSeconds: 10)
        )
        let state = createInitialState(configOverride: patch)

        let next = reduce(state: state, action: .tick(idleSeconds: 0, dtSeconds: 20))

        XCTAssertEqual(next.status, .inWork)
    }

    func testPostponeWorkBreakAdjustsElapsed() {
        let patch = AntiRsiConfigPatch(
            work: WorkBreakConfigPatch(intervalSeconds: 100, durationSeconds: 50, postponeSeconds: 10)
        )
        let state = createInitialState(configOverride: patch)

        let next = reduce(state: state, action: .postponeWorkBreak)

        XCTAssertEqual(next.timings.workElapsed, 90)
        XCTAssertEqual(next.timings.workTaking, 0)
    }

    func testNaturalBreakResetsMiniTimers() {
        let patch = AntiRsiConfigPatch(
            mini: BreakConfigPatch(intervalSeconds: 20, durationSeconds: 10),
            work: WorkBreakConfigPatch(intervalSeconds: 100, durationSeconds: 50, postponeSeconds: 10),
            naturalBreakContinuationWindowSeconds: 5
        )
        let state = createInitialState(configOverride: patch)

        let next = reduce(state: state, action: .tick(idleSeconds: 6, dtSeconds: 2))

        XCTAssertEqual(next.timings.miniElapsed, 0)
        XCTAssertEqual(next.timings.miniTaking, 10)
    }

    func testInhibitorPreventsTicking() {
        var state = createInitialState()
        state.inhibitors.insert("process:zoom")

        let next = reduce(state: state, action: .tick(idleSeconds: 0, dtSeconds: 30))

        XCTAssertEqual(next, state)
    }
}
