// swift-tools-version: 5.9

import PackageDescription

// AppIntents and AppShortcutsProvider are macOS 13+, but the host
// app (KeepingYouAwake) deploys to macOS 10.13. Keep the package's
// platform aligned with the host so SPM can resolve and weak-link
// AppIntents.framework; the source files gate every concrete type
// with `@available(macOS 13.0, *)` and `#if canImport(AppIntents)`.
let package = Package(
    name: "KYAAppIntents",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(name: "KYAAppIntents", targets: ["KYAAppIntents"]),
    ],
    targets: [
        .target(name: "KYAAppIntents"),
    ]
)
