// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-android-native",
    products: [
        .library(name: "AndroidNative", targets: ["AndroidNative"]),
        .library(name: "AndroidAssetManager", targets: ["AndroidAssetManager"]),
        .library(name: "AndroidLogging", targets: ["AndroidLogging"]),
        .library(name: "AndroidLooper", targets: ["AndroidLooper"]),
        .library(name: "AndroidChoreographer", targets: ["AndroidLooper"]),
    ],
    dependencies: [
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
            "AndroidAssetManager",
            "AndroidLogging",
            "AndroidLooper",
            "AndroidChoreographer",
        ]),
        .testTarget(name: "AndroidNativeTests", dependencies: [
            "AndroidNative",
        ]),
    ]
)
