// swift-tools-version:5.7
// Package.swift - Minimal configuration for iOS app structure
// This file helps organize code on Ubuntu. On macOS, create an Xcode project.

import PackageDescription

let package = Package(
    name: "NotesApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "NotesApp",
            targets: ["NotesApp"]
        )
    ],
    targets: [
        .target(
            name: "NotesApp",
            path: "Sources/NotesApp",
            resources: [
                .copy("../Resources")
            ]
        ),
        .testTarget(
            name: "NotesAppTests",
            dependencies: ["NotesApp"],
            path: "Tests/NotesApp"
        )
    ]
)
