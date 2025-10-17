// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"],
        ),
        .library(
            name: "CommonUI",
            targets: ["CommonUI"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "Common",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [
                .defaultIsolation(nil)
            ]
        ),
        .target(
            name: "CommonUI",
            dependencies: [
                .target(name: "Common")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
    ]
)
