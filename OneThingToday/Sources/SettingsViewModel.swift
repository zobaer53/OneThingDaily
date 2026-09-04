import Foundation
import Observation
import OneThingTodayDomain
import OneThingTodayData

@Observable
final class SettingsViewModel {
    private let scheduleUseCase: ScheduleDailyAlarmsUseCase

    var morningTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    var eveningTime: Date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now) ?? .now
    var plan: RelayPlan?
    var errorMessage: String?
    var debugTrace: [String] = []
    /// Seeded from the flag onboarding sets on success, so reopening
    /// Settings doesn't claim alarms aren't scheduled when they already are
    /// — `SchedulingRepository` has no "read current schedule" query, only
    /// authorize/schedule/cancel, so this is the source of truth for display.
    var isScheduled = UserDefaults.standard.bool(forKey: "hasScheduledAlarms")
    /// Alarm permission can only be re-granted from the iOS Settings app once
    /// declined — this drives a distinct "open Settings" affordance instead
    /// of just the generic error text.
    var permissionWasDenied = false

    #if DEBUG
    var debugCompressionFactor: Double {
        get { RelayPolicy.debugCompressionFactor }
        set { RelayPolicy.debugCompressionFactor = newValue }
    }
    #endif

    init(scheduling: SchedulingRepository) {
        self.scheduleUseCase = ScheduleDailyAlarmsUseCase(scheduling: scheduling)
    }

    func reschedule() async {
        errorMessage = nil
        permissionWasDenied = false
        await AlarmDebugLog.shared.clear()
        let calendar = Calendar.current
        let morning = calendar.dateComponents([.hour, .minute], from: morningTime)
        let evening = calendar.dateComponents([.hour, .minute], from: eveningTime)
        do {
            plan = try await scheduleUseCase(morning: morning, evening: evening)
            isScheduled = true
            UserDefaults.standard.set(true, forKey: "hasScheduledAlarms")
        } catch OneThingTodayError.schedulingDenied {
            errorMessage = OneThingTodayError.schedulingDenied.errorDescription
            permissionWasDenied = true
        } catch {
            errorMessage = error.localizedDescription
        }
        // Read the trace back regardless of success/failure so we can see
        // it directly in the app, no Xcode console needed.
        debugTrace = await AlarmDebugLog.shared.snapshot()
    }

    /// Re-reads the trace without touching scheduling — so checking what
    /// happened on the Today tab (Live Activity start/update/end) doesn't
    /// require re-running `reschedule()` and cancelling/rescheduling alarms
    /// just to see the log.
    func refreshDebugTrace() async {
        debugTrace = await AlarmDebugLog.shared.snapshot()
    }
}
