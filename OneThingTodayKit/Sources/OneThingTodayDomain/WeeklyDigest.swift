import Foundation

/// Seven days of sessions + reflections, condensed on-device. Never leaves
/// the phone — there's nowhere for it to go.
public struct WeeklyDigest: Codable, Sendable, Equatable {
    public let generatedAt: Date
    public let daysCompleted: Int
    public let daysTotal: Int
    public let summaryText: String

    public init(generatedAt: Date = .now, daysCompleted: Int, daysTotal: Int, summaryText: String) {
        self.generatedAt = generatedAt
        self.daysCompleted = daysCompleted
        self.daysTotal = daysTotal
        self.summaryText = summaryText
    }
}
