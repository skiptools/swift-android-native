# OSLog for Android

This package provides a Logger API for native Swift on Android compatible with
the [OSLog Logger](https://developer.apple.com/documentation/os/logger)
for Darwin platforms.

# Requirements

  - Swift 5.9
  - [Swift Android SDK](https://github.com/finagolfin/swift-android-sdk)

# Installation

## Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/skiptools/swift-android-oslog.git", from: "1.0.0")
]
```

Then add it as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidOSLog", package: "swift-android-oslog", condition: .when(platforms: [.android]))
])
```

# Usage

## Example

This example will use the system `OSLog` on Darwin platforms and `AndroidOSLog` on Android
to provide common logging functionality across operating systems:

```swift
#if canImport(Darwin)
import OSLog
#elseif os(Android)
import AndroidOSLog
#endif
    
let logger = Logger(subsystem: "Subsystem", category: "Category")

logger.info("Hello Android logcat!")
```

## Viewing Logs

Android log messages for connected devices and emulators
can be viewed from the Terminal using the
[`adb logcat`](https://developer.android.com/tools/logcat) command.
For example, to view only the log message in the example above, you can run:

```
$ adb logcat '*:S' 'Subsystem/Category:I'

10-27 15:53:12.768 22599 22664 I Subsystem/Category: Hello Android logcat!
```

[Android Studio](https://developer.android.com/studio/debug/logcat) provides the ability to
 graphically view and filter log messages, as do most other Android IDEs.

# License

AndroidOSLog is licensed under the Apache 2.0 license with a runtime library exception,
meaning you do not need to attribute the project in your application.
See the [LICENSE](LICENSE) file for details.
