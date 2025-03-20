// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-android-native",
    products: [
        .library(name: "AndroidNative", type: .dynamic, targets: ["AndroidNative"]),
        .library(name: "AndroidContext", type: .dynamic, targets: ["AndroidContext"]),
        .library(name: "AndroidAssetManager", type: .dynamic, targets: ["AndroidAssetManager"]),
        .library(name: "AndroidLogging", type: .dynamic, targets: ["AndroidLogging"]),
        .library(name: "AndroidLooper", type: .dynamic, targets: ["AndroidLooper"]),
        .library(name: "AndroidChoreographer", type: .dynamic, targets: ["AndroidLooper"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/swift-jni.git", "0.0.0"..<"2.0.0"),
    ],
    targets: [
        .target(name: "AndroidNDK", linkerSettings: [
            .linkedLibrary("android", .when(platforms: [.android])),
            .linkedLibrary("log", .when(platforms: [.android])),
        ]),
        .target(name: "ConcurrencyRuntimeC"),
        .target(name: "AndroidSystem", dependencies: [
            .target(name: "AndroidNDK", condition: .when(platforms: [.android]))
        ], swiftSettings: [
            .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: [.macOS, .macCatalyst, .iOS, .watchOS, .tvOS, .visionOS])),
            .define("SYSTEM_PACKAGE"),
        ]),
        .testTarget(name: "AndroidSystemTests", dependencies: [
            "AndroidSystem",
        ]),
        .target(name: "AndroidAssetManager", dependencies: [
            .product(name: "SwiftJNI", package: "swift-jni"),
            .target(name: "AndroidNDK", condition: .when(platforms: [.android])),
        ]),
        .testTarget(name: "AndroidAssetManagerTests", dependencies: [
            "AndroidAssetManager",
        ]),
        .target(name: "AndroidLogging", dependencies: [
            .target(name: "AndroidNDK", condition: .when(platforms: [.android])),
        ]),
        .testTarget(name: "AndroidLoggingTests", dependencies: [
            "AndroidLogging",
        ]),
        .target(name: "AndroidContext", dependencies: [
            "AndroidAssetManager",
            .target(name: "AndroidNDK", condition: .when(platforms: [.android])),
        ]),
        .testTarget(name: "AndroidContextTests", dependencies: [
            "AndroidContext",
        ]),
        .target(name: "AndroidLooper", dependencies: [
            "AndroidSystem",
            "AndroidLogging",
            "ConcurrencyRuntimeC",
        ]),
        .testTarget(name: "AndroidLooperTests", dependencies: [
            "AndroidLooper",
        ]),
        .target(name: "AndroidChoreographer", dependencies: [
            "AndroidSystem",
            "AndroidLogging",
        ]),
        .testTarget(name: "AndroidChoreographerTests", dependencies: [
            "AndroidChoreographer",
        ]),
        .target(name: "AndroidNative", dependencies: [
            "AndroidContext",
            "AndroidLogging",
            "AndroidLooper",
            "AndroidChoreographer",
        ]),
        .testTarget(name: "AndroidNativeTests", dependencies: [
            "AndroidNative",
        ]),
    ]
)
