/// Runs when the Weekly Digest screen appears.
public struct GenerateWeeklyDigestUseCase: Sendable {
    private let sessions: FocusSessionRepository
    private let reflections: ReflectionRepository
    private let ai: AIAssistRepository

    public init(sessions: FocusSessionRepository, reflections: ReflectionRepository, ai: AIAssistRepository) {
        self.sessions = sessions
        self.reflections = reflections
        self.ai = ai
    }

    public func callAsFunction() async throws -> WeeklyDigest {
        let recentSessions = try await sessions.recent(days: 7)
        let recentReflections = try await reflections.recent(days: 7)

        guard await ai.isAvailable else {
            throw OneThingTodayError.aiUnavailable
        }
        guard !recentSessions.isEmpty else {
            throw OneThingTodayError.noDataYet
        }

        let summary = try await ai.summarize(sessions: recentSessions, reflections: recentReflections)
        let completed = recentSessions.filter(\.isDone).count

        return WeeklyDigest(daysCompleted: completed, daysTotal: recentSessions.count, summaryText: summary)
    }
}
