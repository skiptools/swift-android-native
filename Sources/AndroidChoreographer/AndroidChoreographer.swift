// Copyright 2025 Skip
#if os(Android)
import Android
import AndroidNDK
#endif
import AndroidLogging
import CoreFoundation

//let logger = Logger(subsystem: "swift.android.native", category: "AndroidChoreographer")

/// https://developer.android.com/ndk/reference/group/choreographer
@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public final class AndroidChoreographer : @unchecked Sendable {
    private let _choreographer: OpaquePointer

    /// Get the AChoreographer instance for the main thread.
    ///
    /// Must be initialized at startup time with `setupMainChoreographer()`
    public private(set) static var main: AndroidChoreographer!

    /// Get the AChoreographer instance for the current thread.
    ///
    /// This must be called on an ALooper thread.
    public static var current: AndroidChoreographer {
        #if !os(Android)
        fatalError("only implemented for Android")
        #else
        AndroidChoreographer(choreographer: AChoreographer_getInstance())
        #endif
    }

    init(choreographer: OpaquePointer) {
        self._choreographer = choreographer
    }

    /// Add a callback to the Choreographer to  invoke `_dispatch_main_queue_callback_4CF` on each frame to drain the main queue
    public static func setupMainChoreographer() {
        if Self.main == nil {
            //logger.info("setupMainQueue")
            Self.main = AndroidChoreographer.current
            //enqueueMainChoreographer()
        }
    }

    public func postFrameCallback(_ callback: @convention(c)(Int, UnsafeMutableRawPointer?) -> ()) {
        #if !os(Android)
        fatalError("only implemented for Android")
        #else
        AChoreographer_postFrameCallback(_choreographer, callback, nil)
        #endif
    }
}
