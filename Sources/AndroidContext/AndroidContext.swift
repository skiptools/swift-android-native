// Copyright 2025 Skip
import Android
import FoundationEssentials
import SwiftJNI

/// A native reference to
/// [android.content.Context](https://developer.android.com/reference/android/content/Context)
public class AndroidContext : JObject {
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
        let ctx: jobject = try cls.callStatic(method: mth, options: [], args: [])
        return AndroidContext(ctx)
    })

    private static let javaClass = try! JClass(name: "android/content/Context", systemClass: true)

    /// Returns the package name for the current context
    public func getPackageName() throws -> String? {
        try call(method: Self.getPackageNameID, options: [], args: [])
    }
    private static let getPackageNameID = javaClass.getMethodID(name: "getPackageName", sig: "()Ljava/lang/String;")!


    struct ContextError : LocalizedError {
        var errorDescription: String?
    }
}

//public final class JThrowable: JObject {
//    private static let javaClass = try! JClass(name: "java/lang/Throwable", systemClass: true)
//    private static let javaErrorExceptionClass = try! JClass(name: "skip/lib/ErrorException")
//    private static let javaErrorExceptionConstructor = javaErrorExceptionClass.getMethodID(name: "<init>", sig: "(Ljava/lang/String;)V")!
//    /// Handles converting the error pointer into the error that will ultimately be thrown
//    public static var errorConverter: ((JavaObjectPointer, JConvertibleOptions) -> Error?) = { ptr, options in descriptionToError(ptr, options: options) }
//
//    public static func toError(_ ptr: JavaObjectPointer?, options: JConvertibleOptions) -> Error? {
//        guard let ptr else {
//            return nil
//        }
//        return errorConverter(ptr, options)
//    }
//
//    public static func descriptionToError(_ ptr: JavaObjectPointer, options: JConvertibleOptions) -> ThrowableError {
//        let str = try? String.call(toStringID, on: ptr, options: options, args: [])
//        return ThrowableError(description: str ?? "A Java exception occurred, and an error was raised when trying to get the exception message")
//    }
//
//    public static func toThrowable(_ error: (any Error)?, options: JConvertibleOptions) -> JavaObjectPointer? {
//        guard let error else {
//            return nil
//        }
//        guard let convertibleError = error as? JConvertible else {
//            return descriptionToThrowable(error, options: options)
//        }
//        return convertibleError.toJavaObject(options: options)
//    }
//
//    public static func descriptionToThrowable(_ error: any Error, options: JConvertibleOptions) -> JavaObjectPointer {
//        // Note: It would be nice to keep JNI independent of some of the Skip-specific skip.lib.ErrorException, but
//        // if we want to support compatibility with transpiled Swift we need to use Skip types
//        let throwable = try! javaErrorExceptionClass.create(ctor: javaErrorExceptionConstructor, options: options, args: [String(describing: error).toJavaParameter(options: options)])
//        return throwable
//    }
//
//    /// Throw a Swift error to Kotlin.
//    public static func `throw`(_ error: any Error, options: JConvertibleOptions, env: JNIEnvPointer) {
//        let throwable = toThrowable(error, options: options)
//        let jniEnv = env.pointee!.pointee
//        let _ = jniEnv.Throw(env, throwable)
//    }
//
//    public func getMessage() throws -> String? {
//        try call(method: Self.getMessageID, options: [], args: [])
//    }
//    private static let getMessageID = javaClass.getMethodID(name: "getMessage", sig: "()Ljava/lang/String;")!
//
//    public func getLocalizedMessage() throws -> String? {
//        try call(method: Self.getLocalizedMessageID, options: [], args: [])
//    }
//    private static let getLocalizedMessageID = javaClass.getMethodID(name: "getLocalizedMessage", sig: "()Ljava/lang/String;")!
