// swift-tools-version: 5.9
import PackageDescription
import class Foundation.FileManager
import class Foundation.ProcessInfo

let android = Context.environment["TARGET_OS_ANDROID"] ?? "0" != "0"

// Override JNI package
let swiftJavaJNICoreDep: Package.Dependency
if let localPath = Context.environment["SWIFT_JAVA_JNI_CORE_PATH"] {
  swiftJavaJNICoreDep = .package(path: localPath)
} else {
  swiftJavaJNICoreDep = .package(url: "https://github.com/swiftlang/swift-java-jni-core", from: "0.3.0")
}

// Get NDK version from command line
let ndkVersion = ProcessInfo.processInfo.environment["ANDROID_NDK_VERSION"].flatMap { UInt($0) } ?? 27
let ndkVersionDefine = SwiftSetting.define("ANDROID_NDK_VERSION_" + ndkVersion.description)

// Get Android API version
let sdkVersion = ProcessInfo.processInfo.environment["ANDROID_SDK_VERSION"].flatMap { UInt($0) } ?? 28
let sdkVersionDefine = SwiftSetting.define("ANDROID_SDK_VERSION_" + sdkVersion.description)

// Conditionally enable features
let ndkBinder = sdkVersion >= 29 // binder_ndk Requires API 29

let package = Package(
    name: "swift-android-native",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .macCatalyst(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "AndroidNative", targets: ["AndroidNative"]),
        .library(name: "AndroidContext", targets: ["AndroidContext"]),
        .library(name: "AndroidAssetManager", targets: ["AndroidAssetManager"]),
        .library(name: "AndroidLogging", targets: ["AndroidLogging"]),
        .library(name: "AndroidLooper", targets: ["AndroidLooper"]),
        .library(name: "AndroidChoreographer", targets: ["AndroidLooper"]),
    ],
    dependencies: [
        swiftJavaJNICoreDep
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
            .product(name: "SwiftJavaJNICore", package: "swift-java-jni-core"),
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
            "AndroidContext",
            "AndroidLogging",
            "AndroidLooper",
            "AndroidChoreographer",
        ]),
        .testTarget(name: "AndroidNativeTests", dependencies: [
            "AndroidNative",
        ], resources: [.embedInCode("Resources/sample_resource.txt")]),
    ]
    //swiftLanguageModes: [.v5]
)

if android {
    // add compatibility import from OSLog to AndroidLogging
    package.targets += [.target(name: "OSLog", dependencies: ["AndroidLogging"])]
}

