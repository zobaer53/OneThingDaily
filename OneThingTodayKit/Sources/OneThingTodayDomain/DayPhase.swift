/// Where today's session is in its daily arc. Drives which Live Activity
/// copy/state is shown, and which alarm just fired.
public enum DayPhase: String, Codable, Sendable, CaseIterable, Hashable {
    case morning
    case midday
    case evening
}
