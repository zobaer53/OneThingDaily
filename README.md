# One Thing Today

A single-purpose daily-focus iOS app. Full build plan (architecture, the
Live Activity relay engine, phase-by-phase roadmap) lives in the artifact
Claude published earlier — this repo is the code that follows it.

## What's here right now

`OneThingTodayKit/` — a local Swift package, Clean-Architecture style:

- **OneThingTodayDomain** — entities, use cases, repository protocols.
  Pure Swift, no Apple frameworks. Phase 0 + Phase 1, done and tested.
- **OneThingTodayData** — SwiftData persistence (Phase 2), AlarmKit
  scheduling (Phase 3), and the ActivityKit-backed Live Activity + relay
  engine (Phase 4).

`OneThingToday/` — the app target (Today / Schedule screens, composition
root). `OneThingTodayWidget/` — the widget extension target: the Live
Activity's Lock Screen card and Dynamic Island (compact/minimal/expanded).
Both are generated from `project.yml` via `xcodegen generate`.

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

Phase 5 (Foundation Models) is next — on-device "Sharpen" and the weekly
digest summary, with a real fallback for devices/settings where the model
isn't available. Everything before it (Phases 0–4: domain layer,
persistence, AlarmKit scheduling, and the Live Activity relay engine) is
built and passing its exit tests on the iOS 26.2 SDK.
