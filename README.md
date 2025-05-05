# Android Native

This package provides a Swift interface to various
Android [NDK APIs](https://developer.android.com/ndk/reference)
and utilities to integrate Swift Foundation with the Android environment.

## Requirements

- Swift 6
- [Swift Android Toolchain and SDK](https://github.com/skiptools/swift-android-toolchain)

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.0.0")
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
    .product(name: "AndroidLogging", package: "swift-android-native", condition: .when(platforms: [.android]))
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


# AndroidContext

This module provides a minimal wrapper for [android.content.Context](https://developer.android.com/reference/android/content/Context)
that uses [SwiftJNI](https://github.com/skiptools/swift-jni) to bridge into the global application context.

## Installation

Add the `AndroidContext` module as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidContext", package: "swift-android-native", condition: .when(platforms: [.android]))
])
```

## Usage

```swift
let context = try AndroidContext.application
let packageName = try context.getPackageName()
```

## Internals

### Implementation details

By default, the `AndroidContext.application` accessor will try to invoke the JNI method
`android.app.ActivityThread.currentApplication()Landroid/app/Application;` to obtain the
global application context. This can be overridden at app initialization time by setting
the `SWIFT_ANDROID_CONTEXT_FACTORY` environment to a different static accessor, such as:

```swift
// another way to access the global context (deprecated)
setenv("SWIFT_ANDROID_CONTEXT_FACTORY", "android.app.AppGlobals.getInitialApplication()Landroid/app/Application;", 1)

let context = try AndroidContext.application
```

Such setup must be performed before the first time the `AndroidContext.application`
accessor is called, as the result will be cached the first time it is invoked.

Alternatively, if the application bootstrapping code already has access to a
JNI context and `jobject` reference to the application context, it can be
set directly in the static `contextPointer` field. For example,
if your application uses an NDK [ANativeActivity](https://developer.android.com/ndk/reference/struct/a-native-activity)
activity, then the context can be accessed from its reference to the underlying
[android.app.NativeActivity](https://developer.android.com/reference/android/app/NativeActivity)
instance:

```swift
let nativeActivity: ANativeActivity = …
AndroidContext.contextPointer = nativeActivity.clazz
let context = try AndroidContext.application // returns the wrapper around the application context
```


# AndroidAssetManager

This module provides an [AssetManager](https://developer.android.com/ndk/reference/group/asset) API for native Swift on Android.

## Installation

### Swift Package Manager

Add the `AndroidAssetManager` module as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidAssetManager", package: "swift-android-native", condition: .when(platforms: [.android]))
])
```


# AndroidChoreographer

This module provides a [Choreographer](https://developer.android.com/ndk/reference/group/choreographer) API for native Swift on Android.

## Installation

### Swift Package Manager

Add the `AndroidChoreographer` module as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidChoreographer", package: "swift-android-native", condition: .when(platforms: [.android]))
])
```


# AndroidLooper

This module provides a [Looper](https://developer.android.com/ndk/reference/group/looper) API for native Swift on Android.

## Installation

### Swift Package Manager

Add the `AndroidLooper` module as a conditional dependency for any targets that need it:

```swift
.target(name: "MyTarget", dependencies: [
    .product(name: "AndroidLooper", package: "swift-android-native", condition: .when(platforms: [.android]))
])
```

# AndroidBootstrap

The [AndroidBootstrap] class is part of the top-level [AndroidNative] module, and provides
some conveniences for configuring Android to work with other Foundation types.

## Networking

Foundation's `URLSession` cannot load "https" URLs out of the box on Android because it
doesn't know where to look to find the local certificate authority files. In order to
set up `URLSession` properly, first call `AndroidBootstrap.setupCACerts()` one time
in order to initialize the certificate bundle.

For example:

```swift
import Foundation
#if os(Android)
import AndroidNative
import FoundationNetworking
#endif

#if os(Android)
try AndroidBootstrap.setupCACerts() // needed in order to use https
#endif
let url = URL(string: "https://httpbin.org/get?x=1")!
let (data, response) = try await URLSession.shared.data(from: url)
```

# License

Licensed under the Apache 2.0 license with a runtime library exception,
meaning you do not need to attribute the project in your application.
See the [LICENSE](LICENSE) file for details.
