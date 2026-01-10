import Foundation

public enum Action: Equatable {
    case tick(idleSeconds: Double, dtSeconds: Double)
    case setConfig(AntiRsiConfigPatch)
    case resetConfig
    case resetTimings
    case startMiniBreak
    case endMiniBreak
    case startWorkBreak(naturalContinuation: Bool)
    case endWorkBreak
    case postponeWorkBreak
    case setUserPaused(Bool)
    case addInhibitor(String)
    case removeInhibitor(String)
    case setProcesses([String])
}

public struct StoreState: Equatable {
    public var status: AntiRsiState
    public var timings: AntiRsiTimings
    public var lastIdleSeconds: Double
    public var lastUpdatedSeconds: Double
    public var config: AntiRsiConfig
    public var userPaused: Bool
    public var inhibitors: Set<String>
    public var processes: [String]

    public init(
        status: AntiRsiState,
        timings: AntiRsiTimings,
        lastIdleSeconds: Double,
        lastUpdatedSeconds: Double,
        config: AntiRsiConfig,
        userPaused: Bool,
        inhibitors: Set<String>,
        processes: [String]
    ) {
        self.status = status
        self.timings = timings
        self.lastIdleSeconds = lastIdleSeconds
        self.lastUpdatedSeconds = lastUpdatedSeconds
        self.config = config
        self.userPaused = userPaused
        self.inhibitors = inhibitors
        self.processes = processes
    }
}

public func selectIsPaused(_ state: StoreState) -> Bool {
    state.userPaused || !state.inhibitors.isEmpty
}

public func selectSnapshot(_ state: StoreState) -> AntiRsiSnapshot {
    AntiRsiSnapshot(
        state: state.status,
        timings: state.timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        paused: selectIsPaused(state)
    )
}

public func selectConfig(_ state: StoreState) -> AntiRsiConfig {
    state.config
}

public func selectProcesses(_ state: StoreState) -> [String] {
    state.processes
}

public func createInitialState(configOverride: AntiRsiConfigPatch? = nil) -> StoreState {
    let base = defaultAntiRsiConfig()
    let config = configOverride.map { applyPatch(to: base, patch: $0) } ?? base
    return StoreState(
        status: .normal,
        timings: AntiRsiTimings(miniElapsed: 0, miniTaking: 0, workElapsed: 0, workTaking: 0),
        lastIdleSeconds: 0,
        lastUpdatedSeconds: 0,
        config: config,
        userPaused: false,
        inhibitors: [],
        processes: []
    )
}

private func clamp(_ value: Double, min: Double, max: Double) -> Double {
    if value < min { return min }
    if value > max { return max }
    return value
}

private func clampTo(_ value: Double, max: Double) -> Double {
    clamp(value, min: 0, max: max)
}

private func createTimings() -> AntiRsiTimings {
    AntiRsiTimings(miniElapsed: 0, miniTaking: 0, workElapsed: 0, workTaking: 0)
}

private func resetStateWithConfig(_ state: StoreState, _ config: AntiRsiConfig) -> StoreState {
    StoreState(
        status: .normal,
        timings: createTimings(),
        lastIdleSeconds: 0,
        lastUpdatedSeconds: 0,
        config: config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func enterMiniBreak(_ state: StoreState) -> StoreState {
    var timings = state.timings
    timings.miniElapsed = state.config.mini.intervalSeconds
    timings.miniTaking = 0
    return StoreState(
        status: .inMini,
        timings: timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func leaveMiniBreak(_ state: StoreState) -> StoreState {
    var timings = state.timings
    timings.miniElapsed = 0
    timings.miniTaking = state.config.mini.durationSeconds
    return StoreState(
        status: .normal,
        timings: timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func enterWorkBreak(_ state: StoreState, naturalContinuation: Bool) -> StoreState {
    var timings = state.timings
    timings.workElapsed = state.config.work.intervalSeconds
    timings.workTaking = naturalContinuation ? state.timings.workTaking : 0
    timings.miniElapsed = 0
    timings.miniTaking = state.config.mini.durationSeconds
    return StoreState(
        status: .inWork,
        timings: timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func leaveWorkBreak(_ state: StoreState) -> StoreState {
    var timings = state.timings
    timings.miniElapsed = 0
    timings.miniTaking = state.config.mini.durationSeconds
    timings.workElapsed = 0
    timings.workTaking = state.config.work.durationSeconds
    return StoreState(
        status: .normal,
        timings: timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func resetTimings(_ state: StoreState) -> StoreState {
    StoreState(
        status: .normal,
        timings: createTimings(),
        lastIdleSeconds: 0,
        lastUpdatedSeconds: 0,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func postponeWorkBreak(_ state: StoreState) -> StoreState {
    let interval = state.config.work.intervalSeconds
    let postpone = state.config.work.postponeSeconds
    let workElapsed = clamp(interval - postpone, min: 0, max: interval)
    var timings = state.timings
    timings.miniElapsed = 0
    timings.miniTaking = 0
    timings.workElapsed = workElapsed
    timings.workTaking = 0
    return StoreState(
        status: .normal,
        timings: timings,
        lastIdleSeconds: state.lastIdleSeconds,
        lastUpdatedSeconds: state.lastUpdatedSeconds,
        config: state.config,
        userPaused: state.userPaused,
        inhibitors: state.inhibitors,
        processes: state.processes
    )
}

private func shouldResetMiniFromNaturalBreak(idleSeconds: Double, config: AntiRsiConfig) -> Bool {
    idleSeconds >= config.naturalBreakContinuationWindowSeconds
}

private func resetMiniTimersFromNaturalBreak(timings: AntiRsiTimings, config: AntiRsiConfig) -> AntiRsiTimings {
    var next = timings
    next.miniElapsed = 0
    next.miniTaking = config.mini.durationSeconds
    return next
}

private func tick(_ state: StoreState, idleSeconds: Double, dtSeconds: Double) -> StoreState {
    if selectIsPaused(state) {
        return state
    }

    let delta = max(0, dtSeconds)
    if delta == 0 && idleSeconds == state.lastIdleSeconds {
        return state
    }

    var timings = state.timings
    var next = state
    next.timings = timings
    next.lastIdleSeconds = idleSeconds
    next.lastUpdatedSeconds = state.lastUpdatedSeconds + delta

    switch state.status {
    case .normal:
        let idleThreshold = state.config.mini.durationSeconds * 0.3
        if idleSeconds <= idleThreshold {
            timings.miniElapsed = clampTo(timings.miniElapsed + delta, max: state.config.mini.intervalSeconds)
            timings.miniTaking = 0
        } else {
            timings.miniTaking = clampTo(timings.miniTaking + delta, max: state.config.mini.durationSeconds)
        }

        timings.workElapsed = clampTo(timings.workElapsed + delta, max: state.config.work.intervalSeconds)
        timings.workTaking = 0

        let naturalReset = shouldResetMiniFromNaturalBreak(idleSeconds: idleSeconds, config: state.config)
        if naturalReset {
            next.timings = resetMiniTimersFromNaturalBreak(timings: timings, config: state.config)
        } else {
            next.timings = timings
        }

        if next.timings.workElapsed >= state.config.work.intervalSeconds {
            return enterWorkBreak(next, naturalContinuation: false)
        }

        if !naturalReset && next.timings.miniElapsed >= state.config.mini.intervalSeconds {
            return enterMiniBreak(next)
        }

        return next
    case .inMini:
        timings.workElapsed = clampTo(timings.workElapsed + delta, max: state.config.work.intervalSeconds)
        if idleSeconds < 1 {
            timings.miniTaking = 0
        } else {
            timings.miniTaking = clampTo(timings.miniTaking + delta, max: state.config.mini.durationSeconds)
        }

        if timings.workElapsed >= state.config.work.intervalSeconds {
            next.timings = timings
            return enterWorkBreak(next, naturalContinuation: false)
        }

        if timings.miniTaking >= state.config.mini.durationSeconds {
            next.timings = timings
            return leaveMiniBreak(next)
        }

        next.timings = timings
        return next
    case .inWork:
        if idleSeconds >= 4 {
            timings.workTaking = clampTo(timings.workTaking + delta, max: state.config.work.durationSeconds)
        }

        if timings.workTaking >= state.config.work.durationSeconds {
            next.timings = timings
            return leaveWorkBreak(next)
        }

        next.timings = timings
        return next
    }
}

public func reduce(state: StoreState, action: Action) -> StoreState {
    switch action {
    case let .tick(idleSeconds, dtSeconds):
        return tick(state, idleSeconds: idleSeconds, dtSeconds: dtSeconds)
    case let .setConfig(patch):
        let config = applyPatch(to: state.config, patch: patch)
        return resetStateWithConfig(state, config)
    case .resetConfig:
        return resetStateWithConfig(state, defaultAntiRsiConfig())
    case .resetTimings:
        return resetTimings(state)
    case .startMiniBreak:
        return enterMiniBreak(state)
    case .endMiniBreak:
        return leaveMiniBreak(state)
    case let .startWorkBreak(naturalContinuation):
        return enterWorkBreak(state, naturalContinuation: naturalContinuation)
    case .endWorkBreak:
        return leaveWorkBreak(state)
    case .postponeWorkBreak:
        return postponeWorkBreak(state)
    case let .setUserPaused(value):
        if state.userPaused == value {
            return state
        }
        var next = state
        next.userPaused = value
        return next
    case let .addInhibitor(sourceId):
        if state.inhibitors.contains(sourceId) {
            return state
        }
        var next = state
        next.inhibitors.insert(sourceId)
        return next
    case let .removeInhibitor(sourceId):
        if !state.inhibitors.contains(sourceId) {
            return state
        }
        var next = state
        next.inhibitors.remove(sourceId)
        return next
    case let .setProcesses(processes):
        if state.processes == processes {
            return state
        }
        var next = state
        next.processes = processes
        return next
    }
}
