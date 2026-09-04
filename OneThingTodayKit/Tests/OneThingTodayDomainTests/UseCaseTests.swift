import Foundation
import Testing
@testable import OneThingTodayDomain

@Suite("Use cases")
struct UseCaseTests {

    @Test("Starting the morning check-in creates a session and a Live Activity")
    func startMorningCheckIn() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let useCase = StartMorningCheckInUseCase(sessions: sessions, activities: activities)

        let session = try await useCase(taskText: "Write the report", dayID: "2026-09-04")

        #expect(session.taskText == "Write the report")
        #expect(session.currentActivityID != nil)
        #expect(await activities.startCount == 1)
    }

    @Test("Relaying ends the old activity and starts a new one, resetting the clock")
    func relayEndsAndRestarts() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let start = StartMorningCheckInUseCase(sessions: sessions, activities: activities)
        let relay = RelayLiveActivityUseCase(sessions: sessions, activities: activities)

        let session = try await start(taskText: "Write the report", dayID: "2026-09-04")
        try await relay(dayID: session.id)

        let updated = try await sessions.session(id: session.id)
        #expect(await activities.startCount == 2)
        #expect(await activities.endCount == 1)
        #expect(updated?.relayCount == 1)
        #expect(updated?.currentActivityID != session.currentActivityID)
        #expect(updated?.phase == .midday)
    }

    @Test("Sharpening fails cleanly, with a typed error, when AI is unavailable")
    func sharpenFailsWhenUnavailable() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        _ = try await StartMorningCheckInUseCase(sessions: sessions, activities: activities)(
            taskText: "Draft outline", dayID: "2026-09-04"
        )

        let sharpen = SharpenTaskUseCase(sessions: sessions, activities: activities, ai: UnavailableAIAssistRepository())

        await #expect(throws: OneThingTodayError.aiUnavailable) {
            try await sharpen(dayID: "2026-09-04")
        }
    }

    @Test("Sharpening succeeds and pushes the update to the Live Activity")
    func sharpenSucceeds() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        _ = try await StartMorningCheckInUseCase(sessions: sessions, activities: activities)(
            taskText: "work on henderson project", dayID: "2026-09-04"
        )

        let sharpen = SharpenTaskUseCase(sessions: sessions, activities: activities, ai: FakeAIAssistRepository())
        let result = try await sharpen(dayID: "2026-09-04")

        #expect(result.isSharpened)
        #expect(result.taskText == "Sharpened: work on henderson project")
    }

    @Test("Completing the task updates the session without touching the activity's lifetime")
    func completeTaskMarksDone() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let session = try await StartMorningCheckInUseCase(sessions: sessions, activities: activities)(
            taskText: "Ship the PR", dayID: "2026-09-04"
        )

        try await CompleteTaskUseCase(sessions: sessions, activities: activities)(dayID: session.id)

        let updated = try await sessions.session(id: session.id)
        #expect(updated?.isDone == true)
        #expect(await activities.endCount == 0, "completing shouldn't end the Live Activity")
    }

    @Test("Submitting a reflection completes the day and closes the activity with a delay")
    func submitReflectionCompletesDay() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let reflections = FakeReflectionRepository()
        let start = StartMorningCheckInUseCase(sessions: sessions, activities: activities)
        let submit = SubmitReflectionUseCase(sessions: sessions, reflections: reflections, activities: activities)

        let session = try await start(taskText: "Ship the PR", dayID: "2026-09-04")
        try await submit(dayID: session.id, text: "Shipped it, felt great.")

        let updated = try await sessions.session(id: session.id)
        #expect(updated?.state == .completed)
        #expect(await activities.endCount == 1)

        let savedReflections = try await reflections.recent(days: 7)
        #expect(savedReflections.first?.text == "Shipped it, felt great.")
    }

    @Test("Resuming puts a fresh Live Activity back on screen without touching the session's other state")
    func resumeStartsFreshActivity() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let session = try await StartMorningCheckInUseCase(sessions: sessions, activities: activities)(
            taskText: "Write the report", dayID: "2026-09-04"
        )
        // Simulate the Activity having gone stale/vanished: the app never
        // learns about that directly, so nothing clears `currentActivityID`
        // on its own — this just confirms resume overwrites it with a new one.
        let resume = ResumeLiveActivityUseCase(sessions: sessions, activities: activities)

        let resumed = try await resume(dayID: session.id)

        #expect(await activities.startCount == 2)
        #expect(resumed.currentActivityID != session.currentActivityID)
        #expect(resumed.taskText == "Write the report")
    }

    @Test("Resuming with no session for the day throws")
    func resumeThrowsWithoutSession() async throws {
        let sessions = FakeFocusSessionRepository()
        let activities = FakeLiveActivityRepository()
        let resume = ResumeLiveActivityUseCase(sessions: sessions, activities: activities)

        await #expect(throws: OneThingTodayError.noSessionToday) {
            try await resume(dayID: "2026-09-04")
        }
    }

    @Test("Scheduling alarms throws when the user declines the permission")
    func scheduleAlarmsThrowsWhenDenied() async throws {
        let scheduling = FakeSchedulingRepository(authorizationGranted: false)
        let useCase = ScheduleDailyAlarmsUseCase(scheduling: scheduling)

        await #expect(throws: OneThingTodayError.schedulingDenied) {
            try await useCase(morning: DateComponents(hour: 7, minute: 0), evening: DateComponents(hour: 20, minute: 30))
        }
    }

    @Test("Generating a weekly digest summarizes the last 7 days")
    func generateWeeklyDigest() async throws {
        let sessions = FakeFocusSessionRepository()
        let reflections = FakeReflectionRepository()
        for day in 1...3 {
            var s = FocusDaySession(id: "day-\(day)", taskText: "Task \(day)")
            s.isDone = day != 2
            try await sessions.save(s)
        }

        let useCase = GenerateWeeklyDigestUseCase(sessions: sessions, reflections: reflections, ai: FakeAIAssistRepository())
        let digest = try await useCase()

        #expect(digest.daysTotal == 3)
        #expect(digest.daysCompleted == 2)
        #expect(!digest.summaryText.isEmpty)
    }
}
