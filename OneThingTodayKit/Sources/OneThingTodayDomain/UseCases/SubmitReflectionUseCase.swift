import Foundation

/// Fired by the evening alarm: records the one-liner and closes out the day.
public struct SubmitReflectionUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let reflections: ReflectionRepository
    private let activities: LiveActivityRepository

    public init(sessions: FocusSessionRepository, reflections: ReflectionRepository, activities: LiveActivityRepository) {
        self.sessions = sessions
        self.reflections = reflections
        self.activities = activities
    }

    public func callAsFunction(dayID: String, text: String) async throws {
        guard var session = try await sessions.session(id: dayID) else {
            throw OneThingTodayError.noSessionToday
        }

        try await reflections.save(Reflection(id: dayID, text: text))

        session.phase = .evening
        session.state = .completed
        let snapshot = session.contentSnapshot
        try await sessions.save(session)

        if let activityID = session.currentActivityID {
            // Keep the finished card up for a couple of hours as
            // confirmation, then the app retires it itself — comfortably
            // inside the 12-hour hard limit either way.
            await activities.end(activityID, final: snapshot, dismissAfter: 2 * 3600)
        }
    }
}
