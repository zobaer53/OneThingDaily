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
    var hasNoDataYet = false

    init(sessions: FocusSessionRepository, reflections: ReflectionRepository, ai: AIAssistRepository) {
        self.generateUseCase = GenerateWeeklyDigestUseCase(sessions: sessions, reflections: reflections, ai: ai)
        self.ai = ai
    }

    func load() async {
        isAIAvailable = await ai.isAvailable
        guard isAIAvailable else { return }

        errorMessage = nil
        hasNoDataYet = false
        isLoading = true
        defer { isLoading = false }
        do {
            digest = try await generateUseCase()
        } catch OneThingTodayError.noDataYet {
            hasNoDataYet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
