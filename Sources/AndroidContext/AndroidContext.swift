// Copyright 2025 Skip
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#if canImport(Android)
import Android
#elseif canImport(Darwin)
import func Darwin.getenv
#elseif canImport(Glibc)
import func Glibc.getenv
#endif
@_exported import AndroidAssetManager
import SwiftJNI

/// A native reference to
/// [android.content.Context](https://developer.android.com/reference/android/content/Context)
//@available(macOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class AndroidContext : JObject, @unchecked Sendable {
    /// The JNI signature for the method to invoke to obtain the global Context.
    /// This can be manually changed before initialization to a different signature.
    /// It must be a zero-argument static fuction that returns an instance of `android.content.Context`.
    ///
    /// The default value of the factory will be the value of the `SWIFT_ANDROID_CONTEXT_FACTORY` environment variable,
    /// and if unset, will fall back to `android.app.ActivityThread.currentApplication()Landroid/app/Application;`.
    public static var contextFactory = getenv("SWIFT_ANDROID_CONTEXT_FACTORY").flatMap({ String(cString: $0) }) ?? "android.app.ActivityThread.currentApplication()Landroid/app/Application;"

    /// A global pointer to the application context, in case the application environment wants to initialize it directly without going through the factory method.
    public static var contextPointer: JavaObjectPointer? = nil

    /// Returns the application context.
    public static var application: AndroidContext {
        get throws {
            try applicationContext.get()
        }
    }

    /// Obtain the global application context by checking whether the static `contextPointer` is set,
    /// and if not, using the `contextFactory` string to reflectively look up the global context.
    private static let applicationContext: Result<AndroidContext, Error> = Result(catching: {
        try JNI.attachJVM() // ensure that we have a JNI context

        // if we have provided a manual context jobject, then we just use that and skip trying to access the factory
        if let contextPointer = contextPointer {
            return AndroidContext(contextPointer)
        }

        // alternative fallback mechanism:
        //contextFactory = "android.app.AppGlobals.getInitialApplication()Landroid/app/Application;"

        // get the first part of the contextFactory parameter: android.app.ActivityThread
        let contextParts = contextFactory.split(separator: ".")
        let contextType = contextParts.dropLast().joined(separator: ".")
        let contextRemainder = contextParts.last ?? ""

        // get the second part of the contextFactory parameter: currentApplication()Landroid/app/Application;
        let contextFunctionParts = contextRemainder.split(separator: "(")
        if contextFunctionParts.count != 2 {
            throw ContextError(errorDescription: "Invalid contextFactory signature: \(contextFactory)")
        }

        let contextMethod = "" + contextFunctionParts[0]
        let contextSig = "(" + contextFunctionParts[1]

        let cls = try JClass(name: contextType)
        guard let mth = cls.getStaticMethodID(name: contextMethod, sig: contextSig) else {
            throw ContextError(errorDescription: "Unable to find method \(contextMethod)")
        }
        let ctx: JavaObjectPointer = try cls.callStatic(method: mth, options: [], args: [])
        return AndroidContext(ctx)
    })

    private static let javaClass = try! JClass(name: "android/content/Context", systemClass: true)

    /// The `AndroidAssetManager` for this context
    public private(set) lazy var assetManager = JNI.jni.withEnv { _, env in AndroidAssetManager(env: env, peer: self.safePointer()) }

    /// Returns the package name for the current context
    public func getPackageName() throws -> String? {
        try call(method: Self.getPackageNameID, options: [], args: [])
    }
    private static let getPackageNameID = javaClass.getMethodID(name: "getPackageName", sig: "()Ljava/lang/String;")!


    struct ContextError : LocalizedError {
        var errorDescription: String?
    }
}
