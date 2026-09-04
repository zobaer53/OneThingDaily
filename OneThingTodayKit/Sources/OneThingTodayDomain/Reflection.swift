import Foundation

/// The evening one-liner, tied to a day's session by id.
public struct Reflection: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public var text: String
    public let submittedAt: Date

    public init(id: String, text: String, submittedAt: Date = .now) {
        self.id = id
        self.text = text
        self.submittedAt = submittedAt
    }
}
