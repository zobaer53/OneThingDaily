import Foundation
import SwiftData
import OneThingTodayDomain

/// One ModelContainer, backed by the App Group container so the main app
/// and the widget extension (once it exists, Phase 4) read and write the
/// same SwiftData store instead of two separate ones.
public enum SharedModelContainer {
    /// Must match the App Group added to every target's entitlements.
    public static let appGroupID = "group.com.zobaerhossain.onethingtoday"

    public static func make() -> ModelContainer {
        let schema = Schema([FocusDaySessionRecord.self, ReflectionRecord.self])

        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError(
                "App Group '\(appGroupID)' isn't reachable. Check that the App Group " +
                "capability + entitlements are present on every target that calls this, " +
                "and that the App Group is registered against your Apple Developer team."
            )
        }

        let storeURL = groupURL.appendingPathComponent("OneThingToday.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create the shared ModelContainer: \(error)")
        }
    }
}
