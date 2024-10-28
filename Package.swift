// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-android-native",
    products: [
        .library(name: "AndroidLogging", targets: ["AndroidLogging"])
    ],
    targets: [
        .systemLibrary(name: "AndroidNDK"),
        .target(name: "AndroidLogging", dependencies: [.target(name: "AndroidNDK", condition: .when(platforms: [.android]))]),
        .testTarget(name: "AndroidLoggingTests", dependencies: [.target(name: "AndroidLogging")])
    ]
)
