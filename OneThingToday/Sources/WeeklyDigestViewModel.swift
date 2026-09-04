import Foundation
import Observation
import OneThingTodayDomain

@Observable
final class WeeklyDigestViewModel {
    private let generateUseCase: GenerateWeeklyDigestUseCase
    private let ai: AIAssistRepository

    var digest: WeeklyDigest?
    var errorMessage: String?
    var isLoading = false
    var isAIAvailable = true

    init(sessions: FocusSessionRepository, reflections: ReflectionRepository, ai: AIAssistRepository) {
        self.generateUseCase = GenerateWeeklyDigestUseCase(sessions: sessions, reflections: reflections, ai: ai)
        self.ai = ai
    }

    func load() async {
        isAIAvailable = await ai.isAvailable
        guard isAIAvailable else { return }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            digest = try await generateUseCase()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
