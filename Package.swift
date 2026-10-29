// swift-tools-version:5.9
// SPDX-License-Identifier: MIT

import PackageDescription

let package = Package(
    name: "Murmur",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Murmur",
            path: "Sources/Murmur"
        )
    ]
)
