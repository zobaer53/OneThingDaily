/// Wraps the on-device Foundation Models framework. `isAvailable` lets the
/// UI hide AI-dependent affordances gracefully on devices/settings where
/// it doesn't apply, instead of surfacing an error.
public protocol AIAssistRepository: Sendable {
    var isAvailable: Bool { get async }
    func sharpen(_ taskText: String) async throws -> String
    func summarize(sessions: [FocusDaySession], reflections: [Reflection]) async throws -> String
}
