// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "HipLeech",
    products: [
        .library(
            name: "libHipLeech",
            targets: ["libHipLeech"]),
        .executable(
            name: "HipLeech",
            targets: ["HipLeech"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/devedbox/Commander.git", from: "0.5.6"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "1.7.4"),
    ],
    targets: [
        .target(
            name: "libHipLeech",
            dependencies: ["SwiftSoup"]),
        .target(
            name: "HipLeech",
            dependencies: ["libHipLeech", "Commander"]),
        .testTarget(
            name: "libHipLeechTests",
            dependencies: ["libHipLeech"]),
    ]
)
