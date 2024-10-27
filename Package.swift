// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-android-oslog",
    products: [
        .library(name: "AndroidOSLog", targets: ["AndroidOSLog"])
    ],
    targets: [
        .systemLibrary(name: "CAndroidLog"),
        .target(name: "AndroidOSLog", dependencies: [.target(name: "CAndroidLog", condition: .when(platforms: [.android]))]),
        .testTarget(name: "AndroidOSLogTests", dependencies: [.target(name: "AndroidOSLog")])
    ]
)
