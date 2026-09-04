import Foundation
import Observation
import OneThingTodayDomain

/// Depends only on `SchedulingRepository` — the same protocol `SettingsViewModel`
/// uses to reschedule later, so "what onboarding sets up" and "what Settings
/// changes" stay in sync by construction rather than by convention.
@Observable
final class OnboardingViewModel {
    private let scheduleUseCase: ScheduleDailyAlarmsUseCase

    var morningTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now
    var eveningTime: Date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now) ?? .now
    var errorMessage: String?
    var isScheduling = false

    init(scheduling: SchedulingRepository) {
        self.scheduleUseCase = ScheduleDailyAlarmsUseCase(scheduling: scheduling)
    }

    /// Requests alarm authorization and schedules the day's checkpoints.
    /// Returns whether it succeeded, so the view can decide whether to
    /// advance past onboarding.
    func finish() async -> Bool {
        errorMessage = nil
        isScheduling = true
        defer { isScheduling = false }

        let calendar = Calendar.current
        let morning = calendar.dateComponents([.hour, .minute], from: morningTime)
        let evening = calendar.dateComponents([.hour, .minute], from: eveningTime)
        do {
            _ = try await scheduleUseCase(morning: morning, evening: evening)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
