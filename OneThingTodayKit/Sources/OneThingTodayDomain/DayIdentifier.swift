import Foundation

/// The one place "what day is it, for the purposes of a FocusDaySession id"
/// gets decided. Both the Data layer (default `today()` implementations) and
/// the composition root (constructing use-case calls) use this, so there's
/// never a second, slightly-different definition of "today" anywhere.
public enum DayIdentifier {
    public static func today(calendar: Calendar = .current, now: Date = .now) -> String {
        var cal = calendar
        cal.timeZone = calendar.timeZone
        let components = cal.dateComponents([.year, .month, .day], from: now)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
