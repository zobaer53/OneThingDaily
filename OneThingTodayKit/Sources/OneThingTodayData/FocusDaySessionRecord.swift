import Foundation
import SwiftData
import OneThingTodayDomain
import AlarmKit

@Model
public final class FocusDaySessionRecord {
    @Attribute(.unique) public var id: String
    public var taskText: String
    public var isSharpened: Bool
    public var isDone: Bool
    public var phaseRaw: String
    public var stateRaw: String
    public var currentActivityID: String?
    public var activityStartedAt: Date?
    public var relayCount: Int
    public var createdAt: Date
    

    public init(from session: FocusDaySession) {
        id = session.id
        taskText = session.taskText
        isSharpened = session.isSharpened
        isDone = session.isDone
        phaseRaw = session.phase.rawValue
        stateRaw = session.state.rawValue
        currentActivityID = session.currentActivityID
        activityStartedAt = session.activityStartedAt
        relayCount = session.relayCount
        createdAt = session.createdAt
    }

    public func apply(_ session: FocusDaySession) {
        taskText = session.taskText
        isSharpened = session.isSharpened
        isDone = session.isDone
        phaseRaw = session.phase.rawValue
        stateRaw = session.state.rawValue
        currentActivityID = session.currentActivityID
        activityStartedAt = session.activityStartedAt
        relayCount = session.relayCount
    }

    public var asDomain: FocusDaySession {
        FocusDaySession(
            id: id,
            taskText: taskText,
            isSharpened: isSharpened,
            isDone: isDone,
            phase: DayPhase(rawValue: phaseRaw) ?? .morning,
            state: FocusDaySession.State(rawValue: stateRaw) ?? .awaitingMorningInput,
            currentActivityID: currentActivityID,
            activityStartedAt: activityStartedAt,
            relayCount: relayCount,
            createdAt: createdAt
        )
    }
}
