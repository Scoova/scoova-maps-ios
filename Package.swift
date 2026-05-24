// swift-tools-version: 5.9
//
// Copyright 2026 Scoova
// Licensed under the Apache License, Version 2.0.
//
import PackageDescription

let package = Package(
    name: "ScoovaMaps",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "ScoovaMaps",
            targets: ["ScoovaMaps"]
        ),
    ],
    targets: [
        .target(
            name: "ScoovaMaps",
            path: "Sources/ScoovaMaps"
        ),
        .testTarget(
            name: "ScoovaMapsTests",
            dependencies: ["ScoovaMaps"],
            path: "Tests/ScoovaMapsTests"
        ),
    ]
)
