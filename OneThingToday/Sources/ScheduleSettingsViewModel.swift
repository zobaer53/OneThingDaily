import Foundation
import Observation
import OneThingTodayDomain
import OneThingTodayData

@Observable
final class ScheduleSettingsViewModel {
    private let scheduleUseCase: ScheduleDailyAlarmsUseCase

    var morningTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    var eveningTime: Date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now) ?? .now
    var plan: RelayPlan?
    var errorMessage: String?
    var debugTrace: [String] = []
    var isScheduled = false

    #if DEBUG
    var debugCompressionFactor: Double {
        get { RelayPolicy.debugCompressionFactor }
        set { RelayPolicy.debugCompressionFactor = newValue }
    }
    #endif

    init(scheduling: SchedulingRepository) {
        self.scheduleUseCase = ScheduleDailyAlarmsUseCase(scheduling: scheduling)
    }

    func enable() async {
        errorMessage = nil
        await AlarmDebugLog.shared.clear()
        let calendar = Calendar.current
        let morning = calendar.dateComponents([.hour, .minute], from: morningTime)
        let evening = calendar.dateComponents([.hour, .minute], from: eveningTime)
        do {
            plan = try await scheduleUseCase(morning: morning, evening: evening)
            isScheduled = true
        } catch {
            errorMessage = "\(error)"
        }
        // Read the trace back regardless of success/failure so we can see
        // it directly in the app, no Xcode console needed.
        debugTrace = await AlarmDebugLog.shared.snapshot()
    }

    /// Re-reads the trace without touching scheduling — so checking what
    /// happened on the Today tab (Live Activity start/update/end) doesn't
    /// require re-running `enable()` and cancelling/rescheduling alarms
    /// just to see the log.
    func refreshDebugTrace() async {
        debugTrace = await AlarmDebugLog.shared.snapshot()
    }
}
