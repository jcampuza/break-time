import Foundation

public struct AntiRsiEventBatch: Equatable {
    public var events: [AntiRsiEvent]
    public var snapshotChanged: Bool

    public init(events: [AntiRsiEvent], snapshotChanged: Bool) {
        self.events = events
        self.snapshotChanged = snapshotChanged
    }
}

private func breakType(for state: AntiRsiState) -> BreakType? {
    switch state {
    case .inMini:
        return .mini
    case .inWork:
        return .work
    case .normal:
        return nil
    }
}

private func snapshotsEqual(_ prev: AntiRsiSnapshot, _ next: AntiRsiSnapshot) -> Bool {
    prev == next
}

public func deriveEvents(
    prevState: StoreState,
    nextState: StoreState,
    action: Action
) -> AntiRsiEventBatch {
    let prevPaused = selectIsPaused(prevState)
    let nextPaused = selectIsPaused(nextState)

    let prevSnapshot = selectSnapshot(prevState)
    let nextSnapshot = selectSnapshot(nextState)

    var events: [AntiRsiEvent] = []

    if prevPaused != nextPaused {
        events.append(nextPaused ? .paused : .resumed)
    }

    if prevSnapshot.state != nextSnapshot.state {
        let prevBreakType = breakType(for: prevSnapshot.state)
        let nextBreakType = breakType(for: nextSnapshot.state)

        if nextBreakType == .mini {
            events.append(.miniBreakStart)
        } else if nextBreakType == .work {
            let naturalContinuation: Bool
            if case let .startWorkBreak(naturalContinuation: value) = action {
                naturalContinuation = value
            } else {
                naturalContinuation = false
            }
            events.append(.workBreakStart(naturalContinuation: naturalContinuation))
        }

        if let prevBreakType, nextBreakType != prevBreakType {
            events.append(.breakEnd(breakType: prevBreakType))
        }
    } else if let breakType = breakType(for: nextSnapshot.state) {
        events.append(.breakUpdate(breakType: breakType))
    }

    events.append(.statusUpdate)

    return AntiRsiEventBatch(
        events: events,
        snapshotChanged: !snapshotsEqual(prevSnapshot, nextSnapshot)
    )
}
