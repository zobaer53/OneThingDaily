import Foundation

/// One scheduled touchpoint in a day's plan — becomes one AlarmKit alarm
/// in the Data layer.
public struct AlarmCheckpoint: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case morning
        case relay
        case evening
    }

    public let kind: Kind
    /// Local wall-clock time — hour/minute only, re-anchored to "today" by
    /// whatever schedules it.
    public let time: DateComponents

    public init(kind: Kind, time: DateComponents) {
        self.kind = kind
        self.time = time
    }
}

public struct RelayPlan: Codable, Sendable, Equatable {
    public let checkpoints: [AlarmCheckpoint]
    public init(checkpoints: [AlarmCheckpoint]) {
        self.checkpoints = checkpoints
    }
}

/// The answer to "how do we keep a Live Activity alive across a whole day
/// when iOS hard-caps it at 8 hours active / 12 hours total?" — relay it.
///
/// This is a pure function on purpose: the question "how many relay
/// checkpoints does this day need, and when" has nothing to do with
/// ActivityKit, AlarmKit, or any other framework. It's just arithmetic on
/// two times, and it should be exhaustively unit-tested as exactly that.
public enum RelayPolicy {

    /// iOS accepts updates to a Live Activity for at most 8 hours from
    /// when it's requested. This is Apple's real, fixed limit — it can't
    /// actually be compressed, so a release build always uses it as-is.
    public static let realMaxActiveWindow: TimeInterval = 8 * 3600

    /// Relay this much earlier than the hard limit, to absorb clock drift
    /// and the alarm firing a little late.
    public static let realSafetyMargin: TimeInterval = 15 * 60

    #if DEBUG
    /// DEBUG-only dial: divides the real windows above by this factor, so
    /// `relayInterval` — and anything computed from it, like the Live
    /// Activity `staleDate` in `ActivityKitLiveActivityService` — shrinks
    /// from hours to minutes or seconds. This never affects the real,
    /// OS-enforced 8h/12h Live Activity limits, which iOS applies
    /// regardless; it only compresses the point at which *our own* relay
    /// logic decides to act, so the relay/stale/dismiss behavior can be
    /// exercised in a short manual run instead of waiting out a real day.
    /// Stays at `1` (i.e. a no-op) unless a debug build explicitly sets it,
    /// and the whole mechanism compiles out of release builds entirely.
    /// `nonisolated(unsafe)`: a debug-only dial flipped once from a
    /// Settings toggle before a manual test run, not a value under
    /// concurrent read/write pressure — externally synchronized by that
    /// usage pattern rather than by the type system.
    nonisolated(unsafe) public static var debugCompressionFactor: Double = 1
    public static var maxActiveWindow: TimeInterval { realMaxActiveWindow / debugCompressionFactor }
    public static var safetyMargin: TimeInterval { realSafetyMargin / debugCompressionFactor }
    #else
    public static let maxActiveWindow: TimeInterval = realMaxActiveWindow
    public static let safetyMargin: TimeInterval = realSafetyMargin
    #endif

    public static var relayInterval: TimeInterval { maxActiveWindow - safetyMargin }

    /// - Parameters:
    ///   - morning: local hour/minute for the morning check-in alarm.
    ///   - evening: local hour/minute for the evening reflection alarm.
    /// - Returns: a plan with a `.morning` checkpoint, zero or more `.relay`
    ///   checkpoints spaced `relayInterval` apart, and one `.evening`
    ///   checkpoint — always in that order.
    public static func plan(morning: DateComponents, evening: DateComponents) -> RelayPlan {
        var checkpoints: [AlarmCheckpoint] = [AlarmCheckpoint(kind: .morning, time: morning)]

        let span = spanSeconds(from: morning, to: evening)
        var elapsed: TimeInterval = 0
        var cursor = morning

        while elapsed + relayInterval < span {
            cursor = addingSeconds(relayInterval, to: cursor)
            checkpoints.append(AlarmCheckpoint(kind: .relay, time: cursor))
            elapsed += relayInterval
        }

        checkpoints.append(AlarmCheckpoint(kind: .evening, time: evening))
        return RelayPlan(checkpoints: checkpoints)
    }

    /// Minutes-of-day arithmetic — deliberately not `Calendar`/`Date` based,
    /// so this has no dependency on the current date, time zone, or system
    /// calendar and stays trivially testable. If `evening` is at or before
    /// `morning` clock-time, it's treated as being on the following day
    /// (e.g. an evening alarm just after midnight).
    static func spanSeconds(from morning: DateComponents, to evening: DateComponents) -> TimeInterval {
        let start = (morning.hour ?? 0) * 60 + (morning.minute ?? 0)
        var end = (evening.hour ?? 0) * 60 + (evening.minute ?? 0)
        if end <= start { end += 24 * 60 }
        return TimeInterval((end - start) * 60)
    }

    static func addingSeconds(_ seconds: TimeInterval, to time: DateComponents) -> DateComponents {
        let base = (time.hour ?? 0) * 60 + (time.minute ?? 0)
        let total = base + Int(seconds / 60)
        var result = DateComponents()
        result.hour = (total / 60) % 24
        result.minute = total % 60
        return result
    }
}
