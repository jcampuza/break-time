import Foundation

public enum BreakType: String, Codable, Equatable {
    case mini
    case work
}

public enum AntiRsiState: String, Codable, Equatable {
    case normal
    case inMini = "in-mini"
    case inWork = "in-work"
}

public struct AntiRsiTimings: Codable, Equatable {
    public var miniElapsed: Double
    public var miniTaking: Double
    public var workElapsed: Double
    public var workTaking: Double

    public init(miniElapsed: Double, miniTaking: Double, workElapsed: Double, workTaking: Double) {
        self.miniElapsed = miniElapsed
        self.miniTaking = miniTaking
        self.workElapsed = workElapsed
        self.workTaking = workTaking
    }
}

public struct AntiRsiSnapshot: Codable, Equatable {
    public var state: AntiRsiState
    public var timings: AntiRsiTimings
    public var lastIdleSeconds: Double
    public var lastUpdatedSeconds: Double
    public var paused: Bool

    public init(
        state: AntiRsiState,
        timings: AntiRsiTimings,
        lastIdleSeconds: Double,
        lastUpdatedSeconds: Double,
        paused: Bool
    ) {
        self.state = state
        self.timings = timings
        self.lastIdleSeconds = lastIdleSeconds
        self.lastUpdatedSeconds = lastUpdatedSeconds
        self.paused = paused
    }
}

public enum AntiRsiEvent: Equatable {
    case miniBreakStart
    case workBreakStart(naturalContinuation: Bool)
    case breakUpdate(breakType: BreakType)
    case breakEnd(breakType: BreakType)
    case statusUpdate
    case paused
    case resumed
}
