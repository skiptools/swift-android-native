#if os(Android)
import Android
import AndroidNDK
import AndroidLogging
import CoreFoundation

let logger = Logger(subsystem: "AndroidChoreographer", category: "AndroidChoreographer")

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
        AndroidChoreographer(choreographer: AChoreographer_getInstance())
    }

    init(choreographer: OpaquePointer) {
        self._choreographer = choreographer
    }

    /// Add a callback to the Choreographer to  invoke `_dispatch_main_queue_callback_4CF` on each frame to drain the main queue
    public static func setupMainChoreographer() {
        if Self.main == nil {
            logger.info("setupMainQueue")
            Self.main = AndroidChoreographer.current
            //enqueueMainChoreographer()
        }
    }

    public func postFrameCallback(_ callback: @convention(c)(Int, UnsafeMutableRawPointer?) -> ()) {
        AChoreographer_postFrameCallback(_choreographer, callback, nil)
    }
}

// no longer used: we use the AndroidLooper instead, which will be more efficient than trying to drain the main queue on every frame render

//private func enqueueMainChoreographer() {
//    AndroidChoreographer.current.postFrameCallback(choreographerCallback)
//}
//
//// C-compatible callback wrapper
//private var choreographerCallback: AChoreographer_frameCallback64 = { _, _ in
//    // Drain the main queue
//    //_dispatch_main_queue_callback_4CF()
//    while CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, true) == CFRunLoopRunResult.handledSource {
//        // continue handling queued events without a timeout
//    }
//
//    // AChoreographer_postFrameCallback64 is single-shot, so we need to re-enqueue the callback each frame
//    enqueueMainChoreographer()
//}

//// https://github.com/apple-oss-distributions/libdispatch/blob/bd82a60ee6a73b4eca50af028b48643d51aaf1ea/src/queue.c#L8237
//// https://forums.swift.org/t/main-dispatch-queue-in-linux-sdl-app/31708/3
//@_silgen_name("_dispatch_main_queue_callback_4CF")
//func _dispatch_main_queue_callback_4CF()

#endif
