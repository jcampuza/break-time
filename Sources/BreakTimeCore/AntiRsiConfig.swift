import Foundation

public struct BreakConfig: Codable, Equatable {
    public var intervalSeconds: Double
    public var durationSeconds: Double

    public init(intervalSeconds: Double, durationSeconds: Double) {
        self.intervalSeconds = intervalSeconds
        self.durationSeconds = durationSeconds
    }
}

public struct WorkBreakConfig: Codable, Equatable {
    public var intervalSeconds: Double
    public var durationSeconds: Double
    public var postponeSeconds: Double

    public init(intervalSeconds: Double, durationSeconds: Double, postponeSeconds: Double) {
        self.intervalSeconds = intervalSeconds
        self.durationSeconds = durationSeconds
        self.postponeSeconds = postponeSeconds
    }
}

public struct AntiRsiConfig: Codable, Equatable {
    public var mini: BreakConfig
    public var work: WorkBreakConfig
    public var tickIntervalMs: Double
    public var naturalBreakContinuationWindowSeconds: Double

    public init(
        mini: BreakConfig,
        work: WorkBreakConfig,
        tickIntervalMs: Double,
        naturalBreakContinuationWindowSeconds: Double
    ) {
        self.mini = mini
        self.work = work
        self.tickIntervalMs = tickIntervalMs
        self.naturalBreakContinuationWindowSeconds = naturalBreakContinuationWindowSeconds
    }
}

public struct BreakConfigPatch: Equatable {
    public var intervalSeconds: Double?
    public var durationSeconds: Double?

    public init(intervalSeconds: Double? = nil, durationSeconds: Double? = nil) {
        self.intervalSeconds = intervalSeconds
        self.durationSeconds = durationSeconds
    }
}

public struct WorkBreakConfigPatch: Equatable {
    public var intervalSeconds: Double?
    public var durationSeconds: Double?
    public var postponeSeconds: Double?

    public init(
        intervalSeconds: Double? = nil,
        durationSeconds: Double? = nil,
        postponeSeconds: Double? = nil
    ) {
        self.intervalSeconds = intervalSeconds
        self.durationSeconds = durationSeconds
        self.postponeSeconds = postponeSeconds
    }
}

public struct AntiRsiConfigPatch: Equatable {
    public var mini: BreakConfigPatch?
    public var work: WorkBreakConfigPatch?
    public var tickIntervalMs: Double?
    public var naturalBreakContinuationWindowSeconds: Double?

    public init(
        mini: BreakConfigPatch? = nil,
        work: WorkBreakConfigPatch? = nil,
        tickIntervalMs: Double? = nil,
        naturalBreakContinuationWindowSeconds: Double? = nil
    ) {
        self.mini = mini
        self.work = work
        self.tickIntervalMs = tickIntervalMs
        self.naturalBreakContinuationWindowSeconds = naturalBreakContinuationWindowSeconds
    }
}

public func defaultAntiRsiConfig() -> AntiRsiConfig {
    AntiRsiConfig(
        mini: BreakConfig(intervalSeconds: 4 * 60, durationSeconds: 13),
        work: WorkBreakConfig(intervalSeconds: 50 * 60, durationSeconds: 8 * 60, postponeSeconds: 10 * 60),
        tickIntervalMs: 500,
        naturalBreakContinuationWindowSeconds: 30
    )
}

public func applyPatch(to config: AntiRsiConfig, patch: AntiRsiConfigPatch) -> AntiRsiConfig {
    let mini = BreakConfig(
        intervalSeconds: patch.mini?.intervalSeconds ?? config.mini.intervalSeconds,
        durationSeconds: patch.mini?.durationSeconds ?? config.mini.durationSeconds
    )
    let work = WorkBreakConfig(
        intervalSeconds: patch.work?.intervalSeconds ?? config.work.intervalSeconds,
        durationSeconds: patch.work?.durationSeconds ?? config.work.durationSeconds,
        postponeSeconds: patch.work?.postponeSeconds ?? config.work.postponeSeconds
    )
    return AntiRsiConfig(
        mini: mini,
        work: work,
        tickIntervalMs: patch.tickIntervalMs ?? config.tickIntervalMs,
        naturalBreakContinuationWindowSeconds:
            patch.naturalBreakContinuationWindowSeconds ?? config.naturalBreakContinuationWindowSeconds
    )
}
