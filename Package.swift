// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HumeSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "HumeSDK",
            targets: ["HumeSDK"]),
        .executable(
            name: "MinimalTest",
            targets: ["MinimalTest"]),
        .executable(
            name: "ComprehensiveExample",
            targets: ["ComprehensiveExample"]),
    ],
    dependencies: [
        // No external dependencies - using only Foundation and system frameworks
    ],
    targets: [
        .target(
            name: "HumeSDK",
            dependencies: [],
            path: "Sources/HumeSDK",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "HumeSDKTests",
            dependencies: ["HumeSDK"],
            path: "Tests/HumeSDKTests"
        ),
        .executableTarget(
            name: "MinimalTest",
            dependencies: ["HumeSDK"],
            path: "Examples",
            sources: ["MinimalTest.swift"]
        ),
        .executableTarget(
            name: "ComprehensiveExample",
            dependencies: ["HumeSDK"],
            path: "Examples",
            sources: ["ComprehensiveExample.swift"]
        ),
    ]
)