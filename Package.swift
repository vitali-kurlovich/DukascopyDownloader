// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DukascopyDownloader",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DukascopyDownloader",
            targets: ["DukascopyDownloader"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),

        .package(url: "https://github.com/vitali-kurlovich/DukascopyURL.git", from: "1.2.1"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DukascopyDownloader",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "DukascopyURL",
            ]
        ),
        .testTarget(
            name: "DukascopyDownloaderTests",
            dependencies: ["DukascopyDownloader"]
        ),
    ]
)
