// Copyright 2025 Skip
#if os(Android)
import Android
import AndroidNDK
#endif

#if canImport(os)
@_exported import OSLog
#else
public typealias OSLogMessage = String

/// https://developer.android.com/ndk/reference/group/logging
public struct Logger : @unchecked Sendable {
    public let subsystem: String
    public let category: String

    /// Creates a logger for logging to the default subsystem.
    public init() {
        self.subsystem = ""
        self.category = ""
    }

    /// Creates a custom logger for logging to a specific subsystem and category.
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func log(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_INFO, message: message)
        #else
        print("\(logTag) log: \(message)")
        #endif
    }

    public func trace(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_VERBOSE, message: message)
        #else
        print("\(logTag) trace: \(message)")
        #endif
    }

    public func debug(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_DEBUG, message: message)
        #else
        print("\(logTag) debug: \(message)")
        #endif
    }

    public func info(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_INFO, message: message)
        #else
        print("\(logTag) info: \(message)")
        #endif
    }

    public func notice(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_INFO, message: message)
        #else
        print("\(logTag) notice: \(message)")
        #endif
    }

    public func warning(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_WARN, message: message)
        #else
        print("\(logTag) warning: \(message)")
        #endif
    }

    public func error(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_ERROR, message: message)
        #else
        print("\(logTag) error: \(message)")
        #endif
    }

    public func critical(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_ERROR, message: message)
        #else
        print("\(logTag) critical: \(message)")
        #endif
    }

    public func fault(_ message: OSLogMessage) {
        #if os(Android)
        androidLog(priority: ANDROID_LOG_FATAL, message: message)
        #else
        print("\(logTag) fault: \(message)")
        #endif
    }

    public func log(level type: OSLogType, _ message: OSLogMessage) {
        #if os(Android)
        let priority: android_LogPriority
        switch type {
        case .info: priority = ANDROID_LOG_INFO
        case .debug: priority = ANDROID_LOG_DEBUG
        case .error: priority = ANDROID_LOG_ERROR
        case .fault: priority = ANDROID_LOG_FATAL
        default: priority = ANDROID_LOG_DEFAULT
        }

        androidLog(priority: priority, message: message)
        #else
        print("\(logTag) log \(type): \(message)")
        #endif
    }

    private var logTag: String {
        subsystem.isEmpty && category.isEmpty ? "" : (subsystem + "/" + category)
    }

    #if os(Android)
    private func androidLog(priority: android_LogPriority, message: OSLogMessage) {
        //swift_android_log(priority, logTag, messagePtr)
        __android_log_write(Int32(priority.rawValue), logTag, message)
    }
    #endif
}

//extension OSLog.Category {
//    public static let dynamicTracing: OSLog.Category
//    public static let dynamicStackTracing: OSLog.Category
//}
public struct OSLogType : Equatable, RawRepresentable {
    public let rawValue: UInt8

    public init(_ rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

extension OSLogType {
    public static let `default`: OSLogType = OSLogType(0x00)
    public static let info: OSLogType = OSLogType(0x01)
    public static let debug: OSLogType = OSLogType(0x02)
    public static let error: OSLogType = OSLogType(0x10)
    public static let fault: OSLogType = OSLogType(0x11)
}
#endif
