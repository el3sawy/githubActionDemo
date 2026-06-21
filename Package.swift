// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Danger",
    dependencies: [
        .package(
            url: "https://github.com/danger/swift.git",
            from: "3.0.0"
        )
    ]
)