// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KYAAppIntents",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "KYAAppIntents", targets: ["KYAAppIntents"]),
    ],
    targets: [
        .target(name: "KYAAppIntents"),
    ]
)
