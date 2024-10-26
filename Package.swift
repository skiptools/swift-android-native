// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-android-oslog",
    products: [
        .library(name: "AndroidOSLog", targets: ["AndroidOSLog"])
    ],
    targets: [
        .target(name: "CAndroidLog"),
        .target(name: "AndroidOSLog", dependencies: ["CAndroidLog"]),
        .testTarget(name: "AndroidOSLogTests", dependencies: ["AndroidOSLog"])
    ]
)
