// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "leaf",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/leaf-kit.git", from: "1.0.0-beta.2"),
        .package(url: "https://github.com/michaelschlicker/vapor-grpc.git", .revision("569a1828")),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["LeafKit", "Vapor"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf", "XCTVapor"]),
    ]
)
