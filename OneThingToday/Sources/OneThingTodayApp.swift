import SwiftUI

@main
struct OneThingTodayApp: App {
    // Composition root — the one place concrete Data-layer types get built
    // and handed to the Domain-only presentation layer as protocols.
    private let container = AppContainer()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                RootTabView(container: container)
            } else {
                OnboardingView(viewModel: container.makeOnboardingViewModel()) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

private struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(viewModel: container.makeTodayViewModel())
            }
            .tabItem { Label("Today", systemImage: "target") }

            NavigationStack {
                WeeklyDigestView(viewModel: container.makeWeeklyDigestViewModel())
            }
            .tabItem { Label("Weekly Digest", systemImage: "chart.bar.doc.horizontal") }

            NavigationStack {
                SettingsView(viewModel: container.makeSettingsViewModel())
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
