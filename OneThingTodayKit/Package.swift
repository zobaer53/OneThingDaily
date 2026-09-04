// swift-tools-version:6.2
import PackageDescription

// OneThingTodayData now imports AlarmKit (Phase 3), which is iOS-only —
// so this package can no longer also target macOS the way it did in
// Phase 1/2. Going forward, run tests via Xcode with an iPhone Simulator
// selected as the destination, not "My Mac".

let package = Package(
    name: "OneThingTodayKit",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(name: "OneThingTodayDomain", targets: ["OneThingTodayDomain"]),
        .library(name: "OneThingTodayData", targets: ["OneThingTodayData"]),
    ],
    targets: [
        .target(name: "OneThingTodayDomain"),
        .target(name: "OneThingTodayData", dependencies: ["OneThingTodayDomain"]),
        .testTarget(name: "OneThingTodayDomainTests", dependencies: ["OneThingTodayDomain"]),
    ]
)
