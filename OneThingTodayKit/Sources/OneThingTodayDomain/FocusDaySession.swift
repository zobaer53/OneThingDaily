import Foundation

/// One per calendar day. The single source of truth for "today's one thing" —
/// the app, the widget extension, and the Live Activity all read from the
/// same session via `FocusSessionRepository`.
public struct FocusDaySession: Codable, Sendable, Identifiable, Equatable {

    public enum State: String, Codable, Sendable {
        case awaitingMorningInput
        case inProgress
        case awaitingReflection
        case completed
    }

    /// "yyyy-MM-dd" in the user's local calendar — doubles as the id.
    public let id: String

    public var taskText: String
    public var isSharpened: Bool
    public var isDone: Bool
    public var phase: DayPhase
    public var state: State

    /// Identifies the Live Activity currently on screen, if any. Changes
    /// every time `RelayLiveActivityUseCase` runs — the old id is retired,
    /// a new one takes its place, the session id itself never changes.
    public var currentActivityID: String?
    public var activityStartedAt: Date?
    public var relayCount: Int

    public let createdAt: Date

    public init(
        id: String,
        taskText: String = "",
        isSharpened: Bool = false,
        isDone: Bool = false,
        phase: DayPhase = .morning,
        state: State = .awaitingMorningInput,
        currentActivityID: String? = nil,
        activityStartedAt: Date? = nil,
        relayCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.taskText = taskText
        self.isSharpened = isSharpened
        self.isDone = isDone
        self.phase = phase
        self.state = state
        self.currentActivityID = currentActivityID
        self.activityStartedAt = activityStartedAt
        self.relayCount = relayCount
        self.createdAt = createdAt
    }

    /// What gets handed to `LiveActivityRepository`. Keeping this
    /// framework-agnostic here means use cases never need `import ActivityKit`
    /// — the Data-layer implementation maps it onto
    /// `FocusActivityAttributes.ContentState` at the boundary.
    public var contentSnapshot: FocusContentSnapshot {
        FocusContentSnapshot(taskText: taskText, isSharpened: isSharpened, isDone: isDone, phase: phase)
    }
}

public struct FocusContentSnapshot: Codable, Sendable, Equatable {
    public var taskText: String
    public var isSharpened: Bool
    public var isDone: Bool
    public var phase: DayPhase

    public init(taskText: String, isSharpened: Bool, isDone: Bool, phase: DayPhase) {
        self.taskText = taskText
        self.isSharpened = isSharpened
        self.isDone = isDone
        self.phase = phase
    }
}
