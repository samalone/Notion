// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Notion",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Notion",
            targets: ["Notion"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Notion",
            dependencies: ["SwiftyJSON"]),
        .testTarget(
            name: "NotionTests",
            dependencies: ["Notion"]
        ),
    ]
)
