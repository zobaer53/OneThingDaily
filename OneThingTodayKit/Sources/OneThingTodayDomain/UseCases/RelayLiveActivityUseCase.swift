import Foundation

/// Fired by the midday alarm. This is the whole answer to the 8-hour limit:
/// end the current Live Activity and start a fresh one carrying the same
/// content, back-to-back, resetting the clock.
public struct RelayLiveActivityUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let activities: LiveActivityRepository

    public init(sessions: FocusSessionRepository, activities: LiveActivityRepository) {
        self.sessions = sessions
        self.activities = activities
    }

    public func callAsFunction(dayID: String) async throws {
        guard var session = try await sessions.session(id: dayID) else {
            throw OneThingTodayError.noSessionToday
        }

        session.phase = .midday
        let snapshot = session.contentSnapshot

        // No `await Task.sleep` between these two calls — the visible gap
        // on the Lock Screen is at most one SwiftUI re-render, not a
        // noticeable blank period.
        if let oldID = session.currentActivityID {
            await activities.end(oldID, final: snapshot, dismissAfter: 0)
        }
        let newID = try await activities.start(snapshot)

        session.currentActivityID = newID
        session.activityStartedAt = .now
        session.relayCount += 1
        try await sessions.save(session)
    }
}
