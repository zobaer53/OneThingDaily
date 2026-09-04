import Foundation
import Observation
import OneThingTodayDomain

/// Depends only on Domain protocols and use cases — never on SwiftData,
/// ActivityKit, or any other concrete Data-layer type. The composition root
/// (`AppContainer`) is the only place those get constructed and handed
/// in here.
@Observable
final class TodayViewModel {
    private let sessions: FocusSessionRepository
    private let startUseCase: StartMorningCheckInUseCase
    private let completeUseCase: CompleteTaskUseCase
    private let sharpenUseCase: SharpenTaskUseCase
    private let resumeUseCase: ResumeLiveActivityUseCase
    private let ai: AIAssistRepository

    var session: FocusDaySession?
    var draftText: String = ""
    var errorMessage: String?
    var isAISharpenAvailable = false
    var isBusy = false

    init(sessions: FocusSessionRepository, activities: LiveActivityRepository, ai: AIAssistRepository) {
        self.sessions = sessions
        self.ai = ai
        self.startUseCase = StartMorningCheckInUseCase(sessions: sessions, activities: activities)
        self.completeUseCase = CompleteTaskUseCase(sessions: sessions, activities: activities)
        self.sharpenUseCase = SharpenTaskUseCase(sessions: sessions, activities: activities, ai: ai)
        self.resumeUseCase = ResumeLiveActivityUseCase(sessions: sessions, activities: activities)
    }

    /// True once a task has been set for today and it isn't finished yet.
    var hasActiveTask: Bool {
        guard let session else { return false }
        return !session.taskText.isEmpty && !session.isDone
    }

    /// The Live Activity fallback only makes sense once there's something
    /// on-screen to resume and it isn't currently showing.
    var canResumeLiveActivity: Bool {
        hasActiveTask && session?.currentActivityID == nil
    }

    func load() async {
        isAISharpenAvailable = await ai.isAvailable
        do {
            let today = try await sessions.today()
            session = today
            draftText = today.taskText
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sharpen() async {
        guard let id = session?.id else { return }
        await run {
            session = try await sharpenUseCase(dayID: id)
            draftText = session?.taskText ?? draftText
        }
    }

    func start() async {
        await run {
            session = try await startUseCase(taskText: draftText, dayID: DayIdentifier.today())
        }
    }

    func complete() async {
        guard let id = session?.id else { return }
        await run {
            try await completeUseCase(dayID: id)
            session = try await sessions.session(id: id)
        }
    }

    func resumeLiveActivity() async {
        guard let id = session?.id else { return }
        await run {
            session = try await resumeUseCase(dayID: id)
        }
    }

    private func run(_ operation: () async throws -> Void) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
