// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-bloom",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BloomFilter",
            targets: ["BloomFilter"]
        ),
        .executable(
            name: "BloomFilterBuilder",
            targets: ["BloomFilterBuilder"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BloomFilter"
        ),
        .executableTarget(
            name: "BloomFilterBuilder",
            dependencies: [
                "BloomFilter",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "BloomFilterTests",
            dependencies: ["BloomFilter"]
        ),
    ]
)
