import SwiftUI
import OneThingTodayData
import OneThingTodayDomain

@main
struct OneThingTodayApp: App {
    // Composition root — the one place concrete Data-layer types get built
    // and handed to the Domain-only presentation layer as protocols.
    private let sessionsRepository = SwiftDataFocusSessionRepository(container: SharedModelContainer.make())

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ContentView(
                        viewModel: TodayViewModel(
                            sessions: sessionsRepository,
                            activities: ActivityKitLiveActivityService()
                        )
                    )
                }
                .tabItem { Label("Today", systemImage: "target") }

                NavigationStack {
                    ScheduleSettingsView(
                        viewModel: ScheduleSettingsViewModel(
                            scheduling: AlarmKitSchedulingService()
                        )
                    )
                }
                .tabItem { Label("Schedule", systemImage: "alarm") }
            }
        }
    }
}
