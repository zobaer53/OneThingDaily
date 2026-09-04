import Foundation
import Observation
import OneThingTodayDomain

/// Depends only on Domain protocols and use cases — never on SwiftData,
/// ActivityKit, or any other concrete Data-layer type. The composition root
/// (`OneThingTodayApp`) is the only place those get constructed and handed
/// in here.
@Observable
final class TodayViewModel {
    private let sessions: FocusSessionRepository
    private let startUseCase: StartMorningCheckInUseCase
    private let completeUseCase: CompleteTaskUseCase
    private let sharpenUseCase: SharpenTaskUseCase
    private let ai: AIAssistRepository

    var session: FocusDaySession?
    var draftText: String = ""
    var errorMessage: String?
    var isAISharpenAvailable = false

    init(sessions: FocusSessionRepository, activities: LiveActivityRepository, ai: AIAssistRepository) {
        self.sessions = sessions
        self.ai = ai
        self.startUseCase = StartMorningCheckInUseCase(sessions: sessions, activities: activities)
        self.completeUseCase = CompleteTaskUseCase(sessions: sessions, activities: activities)
        self.sharpenUseCase = SharpenTaskUseCase(sessions: sessions, activities: activities, ai: ai)
    }

    func load() async {
        isAISharpenAvailable = await ai.isAvailable
        do {
            let today = try await sessions.today()
            session = today
            draftText = today.taskText
        } catch {
            errorMessage = "\(error)"
        }
    }

    func sharpen() async {
        guard let id = session?.id else { return }
        errorMessage = nil
        do {
            session = try await sharpenUseCase(dayID: id)
            draftText = session?.taskText ?? draftText
        } catch {
            errorMessage = "\(error)"
        }
    }

    func start() async {
        errorMessage = nil
        do {
            session = try await startUseCase(taskText: draftText, dayID: DayIdentifier.today())
        } catch {
            errorMessage = "\(error)"
        }
    }

    func complete() async {
        guard let id = session?.id else { return }
        errorMessage = nil
        do {
            try await completeUseCase(dayID: id)
            session = try await sessions.session(id: id)
        } catch {
            errorMessage = "\(error)"
        }
    }
}
