import Foundation
import FoundationModels
import OneThingTodayDomain

/// The one file that touches `SystemLanguageModel` / `LanguageModelSession`
/// directly. `isAvailable` mirrors the system model's own availability check
/// so the UI can hide AI affordances instead of erroring — Apple Intelligence
/// can be off, the device ineligible, or the model still downloading.
public struct FoundationModelsAIService: AIAssistRepository {

    public init() {}

    public var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    public func sharpen(_ taskText: String) async throws -> String {
        let session = LanguageModelSession(
            instructions: """
            You turn a vague daily task into exactly one concrete, actionable \
            next step. Respond with a short imperative phrase, under 12 words, \
            with no preamble or extra commentary.
            """
        )
        let response = try await session.respond(
            to: "Sharpen this task into one concrete next action: \(taskText)",
            generating: SharpenedTask.self
        )
        return response.content.action
    }

    public func summarize(sessions: [FocusDaySession], reflections: [Reflection]) async throws -> String {
        let session = LanguageModelSession(
            instructions: """
            You write a short, encouraging summary of someone's week based on \
            their daily focus tasks and evening reflections. One paragraph, \
            under 60 words, second person, no bullet points or headings.
            """
        )
        let response = try await session.respond(
            to: "Summarize this week:\n\(Self.transcript(sessions: sessions, reflections: reflections))",
            generating: WeeklySummary.self
        )
        return response.content.summary
    }

    private static func transcript(sessions: [FocusDaySession], reflections: [Reflection]) -> String {
        var lines: [String] = []
        for session in sessions.sorted(by: { $0.createdAt < $1.createdAt }) {
            lines.append("- Task: \(session.taskText) (\(session.isDone ? "done" : "not done"))")
        }
        for reflection in reflections.sorted(by: { $0.submittedAt < $1.submittedAt }) {
            lines.append("- Reflection: \(reflection.text)")
        }
        return lines.joined(separator: "\n")
    }
}

@Generable
private struct SharpenedTask {
    @Guide(description: "One concrete, actionable next step, phrased as a short imperative sentence, under 12 words")
    let action: String
}

@Generable
private struct WeeklySummary {
    @Guide(description: "An encouraging one-paragraph summary of the week, under 60 words, second person, no bullet points")
    let summary: String
}
