import Foundation
import ActivityKit
import OneThingTodayDomain

/// The one file that touches `Activity<FocusActivityAttributes>` directly.
/// Everything above `LiveActivityRepository` — use cases, view models —
/// only ever deals in `FocusContentSnapshot` and an opaque `String` id.
public struct ActivityKitLiveActivityService: LiveActivityRepository {

    public init() {}

    @discardableResult
    public func start(_ snapshot: FocusContentSnapshot) async throws -> String {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        await AlarmDebugLog.shared.add("LiveActivity.start() — areActivitiesEnabled=\(enabled)")
        guard enabled else {
            throw OneThingTodayError.liveActivityUnavailable
        }
        let content = ActivityContent(
            state: snapshot.activityContentState,
            staleDate: staleDate()
        )
        do {
            // `pushType: nil` — no push server anywhere in this app; every
            // update is a local call from the app process or the AlarmKit
            // relay-alarm intent, never a remote push.
            let activity = try Activity<FocusActivityAttributes>.request(
                attributes: FocusActivityAttributes(),
                content: content,
                pushType: nil
            )
            await AlarmDebugLog.shared.add("LiveActivity.start() OK, id=\(activity.id), activityState=\(activity.activityState)")
            return activity.id
        } catch {
            let nsError = error as NSError
            await AlarmDebugLog.shared.add("LiveActivity.start() THREW: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")
            throw error
        }
    }

    public func update(_ id: String, snapshot: FocusContentSnapshot) async throws {
        guard let activity = existingActivity(id) else {
            await AlarmDebugLog.shared.add("LiveActivity.update(\(id)) — no matching activity found (activities.count=\(Activity<FocusActivityAttributes>.activities.count))")
            throw OneThingTodayError.liveActivityUnavailable
        }
        await activity.update(ActivityContent(state: snapshot.activityContentState, staleDate: staleDate()))
        await AlarmDebugLog.shared.add("LiveActivity.update(\(id)) OK")
    }

    public func end(_ id: String, final snapshot: FocusContentSnapshot, dismissAfter: TimeInterval?) async {
        guard let activity = existingActivity(id) else {
            await AlarmDebugLog.shared.add("LiveActivity.end(\(id)) — no matching activity found (activities.count=\(Activity<FocusActivityAttributes>.activities.count))")
            return
        }
        let content = ActivityContent(state: snapshot.activityContentState, staleDate: nil)
        let policy: ActivityUIDismissalPolicy
        if let dismissAfter, dismissAfter > 0 {
            policy = .after(Date.now.addingTimeInterval(dismissAfter))
        } else {
            policy = .immediate
        }
        await activity.end(content, dismissalPolicy: policy)
        await AlarmDebugLog.shared.add("LiveActivity.end(\(id)) OK, dismissAfter=\(String(describing: dismissAfter))")
    }

    private func existingActivity(_ id: String) -> Activity<FocusActivityAttributes>? {
        Activity<FocusActivityAttributes>.activities.first { $0.id == id }
    }

    /// A UI-only cue (dim the card) distinct from — and always well inside
    /// — the OS-enforced 8h/12h limits, which apply no matter what we set
    /// here. Chosen to land right at `relayInterval`, so if the midday
    /// relay alarm is ever missed, the Island itself visibly tells the
    /// user rather than silently going stale with no explanation.
    private func staleDate() -> Date {
        Date.now.addingTimeInterval(RelayPolicy.relayInterval)
    }
}
