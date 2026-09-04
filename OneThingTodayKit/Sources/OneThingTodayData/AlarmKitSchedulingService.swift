import Foundation
import SwiftUI
import ActivityKit
import AppIntents
import AlarmKit
import OneThingTodayDomain

/// Empty on purpose — we don't need any extra per-alarm payload beyond
/// AlarmKit's own alarm id.
struct FocusAlarmMetadata: AlarmMetadata {}

/// Runs when someone taps the alarm's stop button. AlarmManager already
/// stops the alarm itself before invoking this (per Apple's docs).
///
/// For the `.relay` checkpoint specifically, this button *is* the relay
/// trigger: "Yep, still going" both silences the alarm and — right here,
/// in-process — ends the current Live Activity and starts a fresh one,
/// which is the entire fix for the 8-hour Live Activity limit. Morning and
/// evening taps just log; those days' use cases need typed text the alert
/// itself can't collect, so they're driven from the app's own screens
/// instead (Phase 6).
struct StopFocusAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    @Parameter(title: "Checkpoint Kind")
    var kindRawValue: String

    init() {
        self.alarmID = ""
        self.kindRawValue = ""
    }

    init(alarmID: String, kind: AlarmCheckpoint.Kind) {
        self.alarmID = alarmID
        self.kindRawValue = kind.rawValue
    }

    func perform() async throws -> some IntentResult {
        await AlarmDebugLog.shared.add("stop intent fired for alarm \(alarmID), kind=\(kindRawValue)")

        guard kindRawValue == AlarmCheckpoint.Kind.relay.rawValue else {
            return .result()
        }

        let sessions = SwiftDataFocusSessionRepository(container: SharedModelContainer.make())
        let activities = ActivityKitLiveActivityService()
        let relay = RelayLiveActivityUseCase(sessions: sessions, activities: activities)
        do {
            try await relay(dayID: DayIdentifier.today())
            await AlarmDebugLog.shared.add("relay use case completed for \(DayIdentifier.today())")
        } catch {
            let nsError = error as NSError
            await AlarmDebugLog.shared.add("relay use case FAILED: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")
        }
        return .result()
    }
}

/// Wraps AlarmKit. This is the one file in the whole app built against a
/// framework introduced in iOS 26 with a fast-moving API surface (Apple
/// deprecated `AlarmPresentation.Alert`'s `stopButton` parameter in 26.1,
/// one point release after 26.0) — written directly against the real
/// generated interface rather than guessed.
public struct AlarmKitSchedulingService: SchedulingRepository {

    public init() {}

    public func requestAuthorization() async throws -> Bool {
        await AlarmDebugLog.shared.add("requestAuthorization() called")
        let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSAlarmKitUsageDescription") as? String
        let usageDescriptionText = usageDescription ?? "MISSING"
        let bundleIDText = Bundle.main.bundleIdentifier ?? "nil"
        await AlarmDebugLog.shared.add("Info.plist NSAlarmKitUsageDescription = \(usageDescriptionText)")
        await AlarmDebugLog.shared.add("bundle id = \(bundleIDText)")
        let currentState = AlarmManager.shared.authorizationState
        await AlarmDebugLog.shared.add("authorizationState = \(currentState)")
        switch currentState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            await AlarmDebugLog.shared.add("about to call AlarmManager.shared.requestAuthorization()")
            do {
                let state = try await AlarmManager.shared.requestAuthorization()
                await AlarmDebugLog.shared.add("requestAuthorization() returned \(state)")
                return state == .authorized
            } catch {
                let nsError = error as NSError
                await AlarmDebugLog.shared.add("requestAuthorization() THREW: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription) userInfo=\(nsError.userInfo)")
                throw error
            }
        @unknown default:
            return false
        }
    }

    public func scheduleDaily(_ plan: RelayPlan) async throws {
        await AlarmDebugLog.shared.add("scheduleDaily() called with \(plan.checkpoints.count) checkpoint(s)")
        do {
            try await cancelAll()
        } catch {
            // Don't let a failed cleanup of old alarms block scheduling new
            // ones — log it and keep going.
            let nsError = error as NSError
            await AlarmDebugLog.shared.add("cancelAll() failed: domain=\(nsError.domain) code=\(nsError.code) — continuing anyway")
        }
        for (index, checkpoint) in plan.checkpoints.enumerated() {
            do {
                try await schedule(checkpoint: checkpoint, index: index)
            } catch {
                let nsError = error as NSError
                await AlarmDebugLog.shared.add("schedule FAILED at index \(index) (\(checkpoint.kind)): domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription) userInfo=\(nsError.userInfo)")
                throw error
            }
        }
        await AlarmDebugLog.shared.add("scheduleDaily() finished all \(plan.checkpoints.count) checkpoint(s) successfully")
    }

    public func cancelAll() async throws {
        await AlarmDebugLog.shared.add("cancelAll() reading AlarmManager.shared.alarms")
        let existing = try AlarmManager.shared.alarms
        await AlarmDebugLog.shared.add("cancelAll() found \(existing.count) existing alarm(s): \(existing.map(\.id))")
        for alarm in existing {
            try AlarmManager.shared.cancel(id: alarm.id)
        }
        await AlarmDebugLog.shared.add("cancelAll() cancelled \(existing.count) alarm(s)")
    }

    private func schedule(checkpoint: AlarmCheckpoint, index: Int) async throws {
        let time = Alarm.Schedule.Relative.Time(
            hour: checkpoint.time.hour ?? 0,
            minute: checkpoint.time.minute ?? 0
        )

        // AlarmKit has no plain ".daily" recurrence — "every day" is
        // weekly recurrence on all seven days.
        let everyDay: Alarm.Schedule.Relative.Recurrence = .weekly(
            [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        )
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: everyDay))

        let copy = alertCopy(for: checkpoint.kind)
        let id = alarmID(for: checkpoint.kind, index: index)
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: copy.title),
            stopButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: copy.stopLabel),
                textColor: .white,
                systemImageName: copy.systemImage
            )
        )
        let presentation = AlarmPresentation(alert: alert)
        // Passing `metadata:` explicitly — Apple's own docs show only one
        // AlarmAttributes initializer, `init(presentation:metadata:tintColor:)`,
        // with no default for `metadata`.
        let attributes = AlarmAttributes<FocusAlarmMetadata>(
            presentation: presentation,
            metadata: FocusAlarmMetadata(),
            tintColor: .orange
        )

        // `.alarm(...)` static factory — documented as "creates a
        // configuration that behaves like a traditional alarm" (no
        // countdown), as opposed to `init(countdownDuration:...)`.
        let configuration = AlarmManager.AlarmConfiguration<FocusAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopFocusAlarmIntent(alarmID: id.uuidString, kind: checkpoint.kind)
        )

        await AlarmDebugLog.shared.add("scheduling \(checkpoint.kind) at \(checkpoint.time.hour ?? -1):\(checkpoint.time.minute ?? -1) id=\(id)")

        do {
            _ = try await AlarmManager.shared.schedule(
                id: id,
                configuration: configuration
            )
            await AlarmDebugLog.shared.add("scheduled \(checkpoint.kind) OK, id=\(id)")
        } catch {
            let nsError = error as NSError
            await AlarmDebugLog.shared.add("AlarmManager.shared.schedule(id:\(id)) THREW: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription) userInfo=\(nsError.userInfo)")
            throw error
        }
    }

    private func alertCopy(for kind: AlarmCheckpoint.Kind) -> (title: String, stopLabel: String, systemImage: String) {
        switch kind {
        case .morning:
            return ("What's the one thing today?", "Set it", "sunrise")
        case .relay:
            return ("Still on it?", "Yep, still going", "checkmark.circle")
        case .evening:
            return ("How'd today go?", "Reflect", "moon.stars")
        }
    }

    /// Deterministic per (kind, position) so rescheduling — e.g. after the
    /// user changes their times in Settings — replaces the existing alarms
    /// instead of piling up duplicates. `cancelAll()` already runs first in
    /// `scheduleDaily`, but keeping these stable is good hygiene regardless.
    private func alarmID(for kind: AlarmCheckpoint.Kind, index: Int) -> UUID {
        switch kind {
        case .morning:
            return UUID(uuidString: "6F1D1B1E-0000-4000-8000-000000000001")!
        case .evening:
            return UUID(uuidString: "6F1D1B1E-0000-4000-8000-000000000003")!
        case .relay:
            let suffix = String(format: "%012d", 100 + index)
            return UUID(uuidString: "6F1D1B1E-0000-4000-8000-\(suffix)")!
        }
    }
}
