/// The one place today's `FocusDaySession` is read or written. The Data-layer
/// implementation backs this with a SwiftData store in an App Group
/// container, so the app and the widget extension see the same state.
public protocol FocusSessionRepository: Sendable {
    func today() async throws -> FocusDaySession
    func session(id: String) async throws -> FocusDaySession?
    func save(_ session: FocusDaySession) async throws
    func recent(days: Int) async throws -> [FocusDaySession]
}
