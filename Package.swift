// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWEventSource",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "WWEventSource", targets: ["WWEventSource"]),
    ],
    targets: [
        .target(name: "WWEventSource"),
        .testTarget(name: "WWEventSourceTests", dependencies: ["WWEventSource"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
