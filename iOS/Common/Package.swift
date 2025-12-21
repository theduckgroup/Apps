// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [
        .iOS(.v17),
    ],
    products: [
//        .library(
//            name: "AppUI",
//            targets: ["AppUI"]
//        ),
//        .library(
//            name: "Backend",
//            targets: ["Backend"]
//        ),
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
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.1.1"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.5.1"),
        .package(url: "https://github.com/tevelee/SwiftUI-Flow", from: "3.1.0"),
        .package(url: "https://github.com/mongodb/swift-bson", exact: "3.1.0"),
    ],
    targets: [
//        .target(
//            name: "AppUI",
//            dependencies: [
//                "Common",
//                "CommonUI",
//                "Backend",
//                .product(name: "Supabase", package: "supabase-swift"),
//                .product(name: "Flow", package: "SwiftUI-Flow"),
//            ],
//            swiftSettings: [
//                .defaultIsolation(MainActor.self)
//            ]
//        ),
//        .target(
//            name: "Backend",
//            dependencies: [
//                "Common",
//                "CommonUI",
//                .product(name: "SocketIO", package: "socket.io-client-swift"),
//                .product(name: "Supabase", package: "supabase-swift"),
//                .product(name: "SwiftBSON", package: "swift-bson"),
//            ],
//            swiftSettings: [
//                .defaultIsolation(nil)
//            ]
//        ),
        .target(
            name: "Common",
            dependencies: [
                // "Algorithms"
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            swiftSettings: [
                .defaultIsolation(nil)
            ]
        ),
        .target(
            name: "CommonUI",
            dependencies: [
                "Common"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
    ]
)
