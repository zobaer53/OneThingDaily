import Foundation
import Testing
@testable import OneThingTodayDomain

@Suite("DayIdentifier")
struct DayIdentifierTests {
    @Test("Formats as zero-padded yyyy-MM-dd")
    func formatsCorrectly() {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 4
        components.hour = 8
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        #expect(DayIdentifier.today(calendar: calendar, now: date) == "2026-09-04")
    }
}
