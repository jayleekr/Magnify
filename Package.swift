// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Magnify",
    platforms: [
        .macOS(.v13) // macOS 13.0 or later for better ScreenCaptureKit support
    ],
    products: [
        .executable(
            name: "Magnify",
            targets: ["Magnify"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "Magnify",
            dependencies: [],
            path: "Sources/Magnify"
        ),
        .testTarget(
            name: "MagnifyTests",
            dependencies: ["Magnify"],
            path: "Tests"
        ),
    ]
)
