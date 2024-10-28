#if os(Android)
import Android
import AndroidNDK

public typealias OSLogMessage = String

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
        androidLog(priority: ANDROID_LOG_INFO, message: message)
    }

    public func trace(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_VERBOSE, message: message)
    }

    public func debug(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_DEBUG, message: message)
    }

    public func info(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_INFO, message: message)
    }

    public func notice(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_INFO, message: message)
    }

    public func warning(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_WARN, message: message)
    }

    public func error(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_ERROR, message: message)
    }

    public func critical(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_ERROR, message: message)
    }

    public func fault(_ message: OSLogMessage) {
        androidLog(priority: ANDROID_LOG_FATAL, message: message)
    }

    public func log(level type: OSLogType, _ message: OSLogMessage) {
        let priority: android_LogPriority
        switch type {
        case .info: priority = ANDROID_LOG_INFO
        case .debug: priority = ANDROID_LOG_DEBUG
        case .error: priority = ANDROID_LOG_ERROR
        case .fault: priority = ANDROID_LOG_FATAL
        default: priority = ANDROID_LOG_DEFAULT
        }

        androidLog(priority: priority, message: message)
    }

    private var logTag: String {
        subsystem.isEmpty && category.isEmpty ? "" : (subsystem + "/" + category)
    }

    private func androidLog(priority: android_LogPriority, message: OSLogMessage) {
        //swift_android_log(priority, logTag, messagePtr)
        __android_log_write(Int32(priority.rawValue), logTag, message)
    }
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

#elseif canImport(os)
@_exported import OSLog
#endif

