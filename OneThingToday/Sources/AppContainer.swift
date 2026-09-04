import Foundation
import OneThingTodayData
import OneThingTodayDomain

/// The one place concrete Data-layer types get built. Everything below this
/// — view models, views — depends only on Domain protocols, never on
/// SwiftData, ActivityKit, AlarmKit, or Foundation Models directly.
@MainActor
struct AppContainer {
    let sessions: FocusSessionRepository
    let reflections: ReflectionRepository
    let activities: LiveActivityRepository
    let scheduling: SchedulingRepository
    let ai: AIAssistRepository

    init() {
        let modelContainer = SharedModelContainer.make()
        sessions = SwiftDataFocusSessionRepository(container: modelContainer)
        reflections = SwiftDataReflectionRepository(container: modelContainer)
        activities = ActivityKitLiveActivityService()
        scheduling = AlarmKitSchedulingService()
        ai = FoundationModelsAIService()
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(scheduling: scheduling)
    }

    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(sessions: sessions, activities: activities, ai: ai)
    }

    func makeWeeklyDigestViewModel() -> WeeklyDigestViewModel {
        WeeklyDigestViewModel(sessions: sessions, reflections: reflections, ai: ai)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(scheduling: scheduling)
    }
}
