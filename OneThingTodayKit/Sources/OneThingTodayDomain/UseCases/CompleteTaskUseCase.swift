/// User taps the checkmark on the Lock Screen or in the app.
public struct CompleteTaskUseCase: Sendable {
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
        session.isDone = true
        try await sessions.save(session)

        if let activityID = session.currentActivityID {
            try await activities.update(activityID, snapshot: session.contentSnapshot)
        }
    }
}
