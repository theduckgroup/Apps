// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "Backend",
            targets: ["Backend"]
        ),
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
        
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.5.1")
    ],
    targets: [
        .target(
            name: "Backend",
            dependencies: [
                .byName(name: "Common"),
                .byName(name: "CommonUI"),
                .product(name: "Supabase", package: "supabase-swift")
            ],
            swiftSettings: [
                .defaultIsolation(nil)
            ]
        ),
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
