import Foundation
import Testing
@testable import OneThingTodayDomain

@Suite("RelayPolicy — the fix for the 8-hour Live Activity limit")
struct RelayPolicyTests {

    @Test("A short day (under 7h45m) needs no relay at all")
    func shortDayNeedsNoRelay() {
        let morning = DateComponents(hour: 8, minute: 0)
        let evening = DateComponents(hour: 14, minute: 0) // 6h span
        let plan = RelayPolicy.plan(morning: morning, evening: evening)
        #expect(plan.checkpoints.map(\.kind) == [.morning, .evening])
    }

    @Test("A typical 07:00–20:30 day needs exactly one relay, before the 8h mark")
    func typicalDayNeedsOneRelay() {
        let morning = DateComponents(hour: 7, minute: 0)
        let evening = DateComponents(hour: 20, minute: 30) // 13.5h span
        let plan = RelayPolicy.plan(morning: morning, evening: evening)

        #expect(plan.checkpoints.map(\.kind) == [.morning, .relay, .evening])

        let relay = plan.checkpoints[1].time
        let relayMinutes = (relay.hour ?? 0) * 60 + (relay.minute ?? 0)
        #expect(relayMinutes < 15 * 60, "relay must land before 07:00 + 8h = 15:00")
    }

    @Test("A long shift-worker day needs two relays, each spaced under 8h apart")
    func longDayNeedsTwoRelays() {
        let morning = DateComponents(hour: 6, minute: 0)
        let evening = DateComponents(hour: 23, minute: 0) // 17h span
        let plan = RelayPolicy.plan(morning: morning, evening: evening)

        #expect(plan.checkpoints.filter { $0.kind == .relay }.count == 2)
        #expect(plan.checkpoints.first?.kind == .morning)
        #expect(plan.checkpoints.last?.kind == .evening)
    }

    @Test("An evening time past midnight is treated as the following day")
    func eveningPastMidnightIsNextDay() {
        let morning = DateComponents(hour: 22, minute: 0)
        let evening = DateComponents(hour: 1, minute: 0) // 3h span, wraps past midnight
        let plan = RelayPolicy.plan(morning: morning, evening: evening)
        #expect(plan.checkpoints.map(\.kind) == [.morning, .evening])
    }

    @Test("Relay interval always leaves the full 15-minute safety margin")
    func relayIntervalHasSafetyMargin() {
        #expect(RelayPolicy.relayInterval == RelayPolicy.maxActiveWindow - RelayPolicy.safetyMargin)
        #expect(RelayPolicy.relayInterval == 7 * 3600 + 45 * 60)
    }
}
