import Foundation

/// Run at onboarding, and again whenever the user changes their morning/
/// evening times in Settings.
public struct ScheduleDailyAlarmsUseCase: Sendable {
    private let scheduling: SchedulingRepository

    public init(scheduling: SchedulingRepository) {
        self.scheduling = scheduling
    }

    @discardableResult
    public func callAsFunction(morning: DateComponents, evening: DateComponents) async throws -> RelayPlan {
        guard try await scheduling.requestAuthorization() else {
            throw OneThingTodayError.schedulingDenied
        }
        let plan = RelayPolicy.plan(morning: morning, evening: evening)
        try await scheduling.scheduleDaily(plan)
        return plan
    }
}
