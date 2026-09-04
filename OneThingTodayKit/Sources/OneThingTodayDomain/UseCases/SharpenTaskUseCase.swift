/// User taps "Sharpen" — turns a vague task into one concrete next action,
/// on-device, via Foundation Models.
public struct SharpenTaskUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let activities: LiveActivityRepository
    private let ai: AIAssistRepository

    public init(sessions: FocusSessionRepository, activities: LiveActivityRepository, ai: AIAssistRepository) {
        self.sessions = sessions
        self.activities = activities
        self.ai = ai
    }

    @discardableResult
    public func callAsFunction(dayID: String) async throws -> FocusDaySession {
        guard var session = try await sessions.session(id: dayID) else {
            throw OneThingTodayError.noSessionToday
        }
        guard await ai.isAvailable else {
            throw OneThingTodayError.aiUnavailable
        }

        session.taskText = try await ai.sharpen(session.taskText)
        session.isSharpened = true
        try await sessions.save(session)

        if let activityID = session.currentActivityID {
            try await activities.update(activityID, snapshot: session.contentSnapshot)
        }
        return session
    }
}
