// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-android-native",
    products: [
        .library(name: "AndroidNative", targets: ["AndroidNative"]),
        .library(name: "AndroidLogging", targets: ["AndroidLogging"])
    ],
    targets: [
        .systemLibrary(name: "AndroidNDK"),
        .target(name: "AndroidNative", dependencies: ["AndroidLogging"]),
        .testTarget(name: "AndroidNativeTests", dependencies: ["AndroidNative"]),
        .target(name: "AndroidLogging", dependencies: [.target(name: "AndroidNDK", condition: .when(platforms: [.android]))]),
        .testTarget(name: "AndroidLoggingTests", dependencies: ["AndroidLogging"])
    ]
)
