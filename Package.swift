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
