// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Danger",
    defaultLocalization: "en",
    products: [
        .library(name: "DangerDeps", type: .dynamic, targets: ["DangerDependencies"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/danger/swift.git",
            from: "3.0.0"
        )
    ],
    targets: [
        .target(
            name: "DangerDependencies",
            dependencies: [.product(name: "Danger", package: "swift")]
        )
    ]
)
