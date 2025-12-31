// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Subsystems",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Subsystems", targets: [
            "AppModule",
            "Backend",
            "InventoryApp",
            "QuizApp",
            "WeeklySpendingApp"
        ]),
    ],
    dependencies: [
        .package(path: "../../Common"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.1.1"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.5.1"),
        .package(url: "https://github.com/mongodb/swift-bson", from: "3.1.0"),
        .package(url: "https://github.com/ordo-one/equatable.git", from: "1.2.0"),
        .package(url: "https://github.com/tevelee/SwiftUI-Flow", from: "3.1.1"),
    ],
    targets: [
        .target(
            name: "AppModule",
            dependencies: [
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
                .product(name: "Flow", package: "SwiftUI-Flow"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "Backend",
            dependencies: [
                .product(name: "Common", package: "Common"),
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "SwiftBSON", package: "swift-bson"),
            ],
            resources: [
                .copy("LocalIP")
            ],
            swiftSettings: [
                .defaultIsolation(nil),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "InventoryApp",
            dependencies: [
                "AppModule",
                "Backend",
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
            ],
            resources: [
                .copy("Resources.bundle")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "QuizApp",
            dependencies: [
                "AppModule",
                "Backend",
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
                .product(name: "Equatable", package: "equatable"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "WeeklySpendingApp",
            dependencies: [
                "AppModule",
                "Backend",
                .product(name: "Common", package: "Common"),
                .product(name: "CommonUI", package: "Common"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
