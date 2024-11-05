// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MKTools",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(
            name: "MKTools",
            targets: ["MKTools"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MKTools",
            path: "Sources/MKTools" 
        )
    ]
)
