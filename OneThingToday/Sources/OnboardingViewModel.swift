import Foundation
import Observation
import OneThingTodayDomain

/// Depends only on `SchedulingRepository` — the same protocol `SettingsViewModel`
/// uses to reschedule later, so "what onboarding sets up" and "what Settings
/// changes" stay in sync by construction rather than by convention.
@Observable
final class OnboardingViewModel {
    enum FinishOutcome {
        case success
        case permissionDenied
        case otherFailure
    }

    private let scheduleUseCase: ScheduleDailyAlarmsUseCase

    var morningTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    var eveningTime: Date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now) ?? .now
    var errorMessage: String?
    var isScheduling = false
    /// Set once permission has been declined, so the view can offer a way
    /// into the app anyway instead of trapping the user on this screen —
    /// AlarmKit denial can only be reversed from the iOS Settings app, not
    /// by asking again in-process.
    var permissionWasDenied = false

    init(scheduling: SchedulingRepository) {
        self.scheduleUseCase = ScheduleDailyAlarmsUseCase(scheduling: scheduling)
    }

    /// Requests alarm authorization and schedules the day's checkpoints.
    func finish() async -> FinishOutcome {
        errorMessage = nil
        isScheduling = true
        defer { isScheduling = false }

        let calendar = Calendar.current
        let morning = calendar.dateComponents([.hour, .minute], from: morningTime)
        let evening = calendar.dateComponents([.hour, .minute], from: eveningTime)
        do {
            _ = try await scheduleUseCase(morning: morning, evening: evening)
            UserDefaults.standard.set(true, forKey: "hasScheduledAlarms")
            return .success
        } catch OneThingTodayError.schedulingDenied {
            errorMessage = OneThingTodayError.schedulingDenied.errorDescription
            permissionWasDenied = true
            return .permissionDenied
        } catch {
            errorMessage = error.localizedDescription
            return .otherFailure
        }
    }
}
