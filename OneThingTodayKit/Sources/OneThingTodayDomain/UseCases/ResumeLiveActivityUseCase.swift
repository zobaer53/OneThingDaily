import Foundation

/// Fired by the Today screen's "Resume on Lock Screen" fallback — for when
/// no relay ever fired (permission denied, phone off, whatever) and the
/// Live Activity is simply gone. The session itself was never at risk; it
/// lives in `FocusSessionRepository` untouched. This just puts a fresh
/// Activity back on screen carrying the session's current state.
public struct ResumeLiveActivityUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let activities: LiveActivityRepository

    public init(sessions: FocusSessionRepository, activities: LiveActivityRepository) {
        self.sessions = sessions
        self.activities = activities
    }

    @discardableResult
    public func callAsFunction(dayID: String) async throws -> FocusDaySession {
        guard var session = try await sessions.session(id: dayID) else {
            throw OneThingTodayError.noSessionToday
        }

        let activityID = try await activities.start(session.contentSnapshot)
        session.currentActivityID = activityID
        session.activityStartedAt = .now
        try await sessions.save(session)
        return session
    }
}
