/// Wraps AlarmKit. Nothing above this protocol knows `AlarmManager` exists.
public protocol SchedulingRepository: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleDaily(_ plan: RelayPlan) async throws
    func cancelAll() async throws
}
