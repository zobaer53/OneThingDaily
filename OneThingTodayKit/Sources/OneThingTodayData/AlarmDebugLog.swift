import Foundation

/// A tiny in-memory trace buffer for AlarmKit scheduling calls.
///
/// This exists because `print()` output depends on the Xcode console
/// actually being visible/unfiltered, and in practice that's turned out to
/// be unreliable to coordinate over chat. Anything logged here can instead
/// be read back and shown directly in the app's own UI, so there's no
/// dependency on where or whether Xcode's console is showing anything.
public actor AlarmDebugLog {
    public static let shared = AlarmDebugLog()

    private var lines: [String] = []

    private init() {}

    public func add(_ line: String) {
        lines.append(line)
        // Keep trying stdout too, in case the console *is* working.
        print("[AlarmKit] \(line)")
    }

    public func snapshot() -> [String] {
        lines
    }

    public func clear() {
        lines.removeAll()
    }
}
