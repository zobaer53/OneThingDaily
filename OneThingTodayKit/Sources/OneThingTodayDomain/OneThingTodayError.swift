import Foundation

public enum OneThingTodayError: LocalizedError, Sendable, Equatable {
    case noSessionToday
    case schedulingDenied
    case aiUnavailable
    case liveActivityUnavailable

    public var errorDescription: String? {
        switch self {
        case .noSessionToday:
            return "There's no focus session started for today yet."
        case .schedulingDenied:
            return "Alarm permission was declined, so daily reminders can't be scheduled."
        case .aiUnavailable:
            return "On-device AI isn't available on this device right now."
        case .liveActivityUnavailable:
            return "Live Activities aren't available — check Settings > Face ID & Passcode > Live Activities."
        }
    }
}
