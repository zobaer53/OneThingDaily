import Foundation

/// Fired by the morning alarm: turns "what's the one thing today" into a
/// live session and puts it on the Lock Screen.
public struct StartMorningCheckInUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let activities: LiveActivityRepository

    public init(sessions: FocusSessionRepository, activities: LiveActivityRepository) {
        self.sessions = sessions
        self.activities = activities
    }

    @discardableResult
    public func callAsFunction(taskText: String, dayID: String) async throws -> FocusDaySession {
        var session = FocusDaySession(id: dayID, taskText: taskText, phase: .morning, state: .inProgress)
        let activityID = try await activities.start(session.contentSnapshot)
        session.currentActivityID = activityID
        session.activityStartedAt = .now
        try await sessions.save(session)
        return session
    }
}
