import Foundation
import Observation
import BreakTimeCore

@MainActor
@Observable
final class BreakTimeEngine {
    var state: StoreState
    var isRunning = false

    private let clock = ContinuousClock()
    private var lastTickInstant: ContinuousClock.Instant?
    private var tickTask: Task<Void, Never>?
    private var systemMonitor: SystemEventMonitor?
    private var processMonitor: WorkspaceProcessMonitor?
    private let configStore: ConfigStore
    private let idleProvider: IdleTimeProviding
    @ObservationIgnored private var overlayManager: OverlayManager? = nil

    init(
        configStore: ConfigStore = ConfigStore(),
        idleProvider: IdleTimeProviding = SystemIdleTimeProvider()
    ) {
        self.configStore = configStore
        self.idleProvider = idleProvider
        var initialState = createInitialState()
        if let stored = configStore.load() {
            initialState.config = stored
        }
        self.state = initialState
        self.overlayManager = OverlayManager(engine: self)
    }

    var snapshot: AntiRsiSnapshot {
        selectSnapshot(state)
    }

    var config: AntiRsiConfig {
        state.config
    }

    var processes: [String] {
        state.processes
    }

    var isPaused: Bool {
        selectIsPaused(state)
    }

    func startIfNeeded() {
        guard !isRunning else { return }
        isRunning = true
        syncTickLoop()
        startProcessMonitor()
        startSystemMonitor()
    }

    func startWorkBreak(naturalContinuation: Bool = false) {
        dispatch(.startWorkBreak(naturalContinuation: naturalContinuation))
    }

    func startMiniBreak() {
        dispatch(.startMiniBreak)
    }

    func postponeWorkBreak() {
        dispatch(.postponeWorkBreak)
    }

    func skipWorkBreak() {
        guard !selectIsPaused(state) else { return }
        dispatch(.endWorkBreak)
    }

    func skipMiniBreak() {
        guard !selectIsPaused(state) else { return }
        dispatch(.endMiniBreak)
    }

    func resetTimings() {
        dispatch(.resetTimings)
    }

    func applyConfig(mini: BreakConfig, work: WorkBreakConfig) {
        let patch = AntiRsiConfigPatch(
            mini: BreakConfigPatch(intervalSeconds: mini.intervalSeconds, durationSeconds: mini.durationSeconds),
            work: WorkBreakConfigPatch(
                intervalSeconds: work.intervalSeconds,
                durationSeconds: work.durationSeconds,
                postponeSeconds: work.postponeSeconds
            )
        )
        dispatch(.setConfig(patch))
    }

    func resetConfig() {
        dispatch(.resetConfig)
    }

    func setUserPaused(_ value: Bool) {
        dispatch(.setUserPaused(value))
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
        processMonitor?.stop()
        processMonitor = nil
        systemMonitor?.stop()
        systemMonitor = nil
    }

    func dispatch(_ action: Action) {
        let prevState = state
        let nextState = reduce(state: state, action: action)
        state = nextState

        let batch = deriveEvents(prevState: prevState, nextState: nextState, action: action)
        if !batch.events.isEmpty {
            let snapshot = selectSnapshot(nextState)
            for event in batch.events {
                overlayManager?.handle(event: event, snapshot: snapshot)
            }
        }

        if prevState.config != nextState.config {
            configStore.save(nextState.config)
            if prevState.config.tickIntervalMs != nextState.config.tickIntervalMs && !selectIsPaused(nextState) {
                restartTickLoop()
            }
        }

        if selectIsPaused(prevState) != selectIsPaused(nextState) {
            syncTickLoop()
        }
    }

    func updateProcesses(_ list: [String]) {
        dispatch(.setProcesses(list))
        if list.isEmpty {
            dispatch(.removeInhibitor("process:zoom"))
        } else {
            dispatch(.addInhibitor("process:zoom"))
        }
    }

    private func handleTick() {
        let now = clock.now
        let last = lastTickInstant
        let delta: Double
        if let last {
            let duration = last.duration(to: now)
            let components = duration.components
            delta = Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
        } else {
            delta = 0
        }
        lastTickInstant = now
        let idleSeconds = idleProvider.idleTimeSeconds()
        dispatch(.tick(idleSeconds: idleSeconds, dtSeconds: delta))
    }

    private func restartTickLoop() {
        tickTask?.cancel()
        tickTask = nil
        guard !selectIsPaused(state) else {
            lastTickInstant = nil
            return
        }

        let intervalMs = max(100, config.tickIntervalMs)
        let interval = Duration.milliseconds(Int64(intervalMs.rounded()))
        tickTask = Task { @MainActor in
            lastTickInstant = clock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                handleTick()
            }
        }
    }

    private func syncTickLoop() {
        if selectIsPaused(state) {
            tickTask?.cancel()
            tickTask = nil
            lastTickInstant = nil
        } else {
            restartTickLoop()
        }
    }

    private func startProcessMonitor() {
        let monitor = WorkspaceProcessMonitor(watchedBundleIds: WatchedApps.bundleIdentifiers)
        monitor.start { [weak self] list in
            self?.updateProcesses(list)
        }
        processMonitor = monitor
    }

    private func startSystemMonitor() {
        let monitor = SystemEventMonitor(
            onSuspend: { [weak self] in
                Task { @MainActor in
                    self?.dispatch(.addInhibitor("system:suspend"))
                }
            },
            onResume: { [weak self] in
                Task { @MainActor in
                    self?.dispatch(.removeInhibitor("system:suspend"))
                }
            },
            onLock: { [weak self] in
                Task { @MainActor in
                    self?.dispatch(.addInhibitor("system:lock"))
                }
            },
            onUnlock: { [weak self] in
                Task { @MainActor in
                    self?.dispatch(.removeInhibitor("system:lock"))
                }
            }
        )
        monitor.start()
        systemMonitor = monitor
    }
}
