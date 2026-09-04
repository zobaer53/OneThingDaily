# One Thing Today

A single-purpose daily-focus iOS app.

## What's here right now

`OneThingTodayKit/` — a local Swift package, Clean-Architecture style:

- **OneThingTodayDomain** — entities, use cases, repository protocols.
  Pure Swift, no Apple frameworks. Phase 0 + Phase 1, done and tested.
- **OneThingTodayData** — SwiftData persistence (Phase 2), AlarmKit
  scheduling (Phase 3), the ActivityKit-backed Live Activity + relay
  engine (Phase 4), and the on-device Foundation Models AI service
  (Phase 5).

`OneThingToday/` — the app target: onboarding, and the Today / Weekly
Digest / Settings screens, each with its own `@Observable` view model,
wired up by `AppContainer` (the composition root). `OneThingTodayWidget/`
— the widget extension target: the Live Activity's Lock Screen card and
Dynamic Island (compact/minimal/expanded). Both are generated from
`project.yml` via `xcodegen generate`.

## Try it right now

Whole app + widget extension, in Xcode:

```
xcodegen generate   # regenerate OneThingToday.xcodeproj after editing project.yml
open OneThingToday.xcodeproj
```

Build/run the `OneThingToday` scheme on an iOS 26+ simulator or device.

Domain-only tests (no device needed, but run via Xcode/xcodebuild against
an iOS Simulator destination — `OneThingTodayData` now imports AlarmKit +
ActivityKit, so the package is iOS-only and a plain `swift test` on macOS
will fail on Foundation availability, not a real bug):

```
cd OneThingTodayKit
xcodebuild test -scheme OneThingTodayKit-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## What's next

Phase 7 (polish & App Store prep) is next — app icon, empty/permission-denied/
unsupported-device states, optional StoreKit gating for the digest, Privacy
Nutrition Label, and real screenshots. Everything before it (Phases 0–6:
domain layer, persistence, AlarmKit scheduling, the Live Activity relay
engine, on-device Foundation Models, and the onboarding/Today/Weekly Digest/
Settings screens) is built. Not yet re-verified by `xcodebuild` on this
machine after a local Xcode update to 26.6 left only iOS 26.2/18.5 simulator
runtimes installed (26.5 — Xcode's default SDK — isn't); build/run it in
Xcode.app, which can fetch the missing platform on open.
