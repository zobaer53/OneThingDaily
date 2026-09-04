import Foundation

/// Wraps ActivityKit. `String` stands in for `Activity<FocusActivityAttributes>.ID`
/// at this layer, so Domain never needs `import ActivityKit`.
public protocol LiveActivityRepository: Sendable {
    @discardableResult
    func start(_ snapshot: FocusContentSnapshot) async throws -> String

    func update(_ id: String, snapshot: FocusContentSnapshot) async throws

    /// `dismissAfter` of `0` clears it immediately (used mid-relay); a
    /// positive value keeps the finished card up for confirmation (used
    /// after the evening reflection) — either way, well inside the 12-hour
    /// hard limit.
    func end(_ id: String, final snapshot: FocusContentSnapshot, dismissAfter: TimeInterval?) async
}
