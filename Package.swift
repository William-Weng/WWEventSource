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
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWRegularExpression", from: "1.0.1"),
    ],
    targets: [
        .target(name: "WWEventSource", dependencies: ["WWRegularExpression"], resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
