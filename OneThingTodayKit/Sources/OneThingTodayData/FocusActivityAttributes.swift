import Foundation
import ActivityKit
import OneThingTodayDomain

/// The one type both OS processes need to agree on: the app (which starts/
/// ends activities) and the widget extension (which renders them) both link
/// `OneThingTodayData`, so both see the same `ActivityAttributes` type.
/// Everything above this file — use cases, view models — only ever sees
/// `FocusContentSnapshot` via the `LiveActivityRepository` protocol.
public struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var taskText: String
        public var isSharpened: Bool
        public var isDone: Bool
        public var phase: DayPhase

        public init(taskText: String, isSharpened: Bool, isDone: Bool, phase: DayPhase) {
            self.taskText = taskText
            self.isSharpened = isSharpened
            self.isDone = isDone
            self.phase = phase
        }
    }

    public init() {}
}

extension FocusContentSnapshot {
    var activityContentState: FocusActivityAttributes.ContentState {
        .init(taskText: taskText, isSharpened: isSharpened, isDone: isDone, phase: phase)
    }
}

extension FocusActivityAttributes.ContentState {
    var snapshot: FocusContentSnapshot {
        FocusContentSnapshot(taskText: taskText, isSharpened: isSharpened, isDone: isDone, phase: phase)
    }
}
