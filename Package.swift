// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreakTime",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "BreakTime", targets: ["BreakTime"]),
        .library(name: "BreakTimeCore", targets: ["BreakTimeCore"]),
    ],
    targets: [
        .target(name: "BreakTimeCore"),
        .executableTarget(
            name: "BreakTime",
            dependencies: ["BreakTimeCore"]
        ),
        .testTarget(
            name: "BreakTimeCoreTests",
            dependencies: ["BreakTimeCore"]
        ),
    ]
)
