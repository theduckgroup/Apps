// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Subsystems",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Subsystems", targets: ["AppShared", "QuizApp", "WeeklySpendingApp"]),
        // .library(name: "WeeklySpendingApp", targets: ["WeeklySpendingApp"]),
        // .library(name: "AppShared", targets: ["AppShared"]),
    ],
    dependencies: [
        .package(path: "../../Common"),
    ],
    targets: [
        .target(
            name: "QuizApp",
            dependencies: [
                "AppShared",
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "WeeklySpendingApp",
            dependencies: [
                "AppShared",
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "AppShared",
            dependencies: [
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        )
    ]
)
