import Foundation
import OneThingTodayDomain

/// Temporary stand-in until the real AlarmKit-backed implementation lands
/// in OneThingTodayData. Always "succeeds" so the Schedule screen and the
/// already-tested RelayPolicy logic can be exercised in the running app
/// right now, before AlarmKit's exact API is confirmed.
struct NoopSchedulingRepository: SchedulingRepository {
    func requestAuthorization() async throws -> Bool { true }
    func scheduleDaily(_ plan: RelayPlan) async throws {}
    func cancelAll() async throws {}
}
