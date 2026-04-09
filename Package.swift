// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VoyagerLogger",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macCatalyst(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "VoyagerLogger",
            targets: ["VoyagerLogger"]
        ),
    ],
    targets: [
        .target(
            name: "VoyagerLogger",
            swiftSettings: [
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
            ],
            linkerSettings: [
                .unsafeFlags(["-Wl,-dead_strip"], .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "VoyagerLoggerTests",
            dependencies: ["VoyagerLogger"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
