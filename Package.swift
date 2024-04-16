// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EventStoreModel",
    products: [
        .library(
            name: "Source",
            targets: ["Source"]),
        .library(
            name: "Projection",
            targets: ["Projection"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Source",
            dependencies: []),
        .testTarget(
            name: "SourceTests",
            dependencies: ["Source"]),
        .target(
            name: "Projection",
            dependencies: []),
        .testTarget(
            name: "ProjectionTests",
            dependencies: ["Projection"]),
    ]
)
