# Android Native

This package provides a Swift interface to various
Android [NDK APIs](https://developer.android.com/ndk/reference).

## Requirements

- Swift 5.9
- [Swift Android SDK](https://github.com/finagolfin/swift-android-sdk)

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/skiptools/swift-android-logging.git", from: "1.0.0")
]
```

# AndroidLogging

This module provides a Logger API for native Swift on Android compatible with
the [OSLog Logger](https://developer.apple.com/documentation/os/logger)
for Darwin platforms.

## Installation

### Swift Package Manager

Add the `AndroidLogging` module as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidLogging", package: "swift-android-logging", condition: .when(platforms: [.android]))
])
```

## Usage

### Example

This example will use the system `OSLog` on Darwin platforms and `AndroidLogging` on Android
to provide common logging functionality across operating systems:

```swift
#if canImport(Darwin)
import OSLog
#elseif os(Android)
import AndroidLogging
#endif
    
let logger = Logger(subsystem: "Subsystem", category: "Category")

logger.info("Hello Android logcat!")
```

### Viewing Logs

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

## Internals

### Implementation details

The `Logger` functions will forward messages to the NDK
[__android_log_write](https://developer.android.com/ndk/reference/group/logging#group___logging_1ga32a7173b092ec978b50490bd12ee523b)
function.

### Limitations

- `OSLogMessage` is simply a typealias to `Swift.String`, and does not implement any of the [redaction features](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code#3665948) of the Darwin version.
- 

## License

Licensed under the Apache 2.0 license with a runtime library exception,
meaning you do not need to attribute the project in your application.
See the [LICENSE](LICENSE) file for details.
