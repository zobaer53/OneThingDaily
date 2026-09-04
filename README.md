# One Thing Today

A single-purpose daily-focus iOS app. Full build plan (architecture, the
Live Activity relay engine, phase-by-phase roadmap) lives in the artifact
Claude published earlier — this repo is the code that follows it.

## What's here right now

`OneThingTodayKit/` — a local Swift package, Clean-Architecture style:

- **OneThingTodayDomain** — entities, use cases, repository protocols.
  Pure Swift, no Apple frameworks. Phase 0 + Phase 1, done and tested.
- **OneThingTodayData** — SwiftData persistence (Phase 2), AlarmKit
  scheduling (Phase 3), the ActivityKit-backed Live Activity + relay
  engine (Phase 4), and the on-device Foundation Models AI service
  (Phase 5).

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

Phase 6 (app presentation layer) is next — onboarding, the real Today/Weekly
Digest/Settings screens, and polish beyond the placeholder UI used to prove
out each phase so far. Everything before it (Phases 0–5: domain layer,
persistence, AlarmKit scheduling, the Live Activity relay engine, and the
on-device Foundation Models "Sharpen" + weekly digest summary) is built and
passing its exit tests on the iOS 26.2 SDK.
