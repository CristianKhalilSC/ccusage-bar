// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ccusage-bar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ccusage-bar", targets: ["ccusageBarApp"]),
        .executable(name: "ccusage-core-tests", targets: ["ccusageCoreTests"]),
        .library(name: "ccusageCore", targets: ["ccusageCore"])
    ],
    targets: [
        .executableTarget(
            name: "ccusageBarApp",
            dependencies: ["ccusageCore"],
            path: "Sources/ccusageBarApp",
            resources: [
                .copy("Resources")
            ]
        ),
        .target(
            name: "ccusageCore",
            path: "Sources/ccusageCore"
        ),
        .executableTarget(
            name: "ccusageCoreTests",
            dependencies: ["ccusageCore"],
            path: "Tests/ccusageCoreTests",
            resources: [
                .copy("../Fixtures")
            ]
        )
    ]
)
