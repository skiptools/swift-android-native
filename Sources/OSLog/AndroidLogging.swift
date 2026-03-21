// Copyright 2025 Skip
#if os(Android)
import Android
import AndroidNDK
#endif

#if canImport(os)
@_exported import OSLog
#else
import AndroidLogging

public typealias OSLogMessage = String

/// https://developer.android.com/ndk/reference/group/logging
public struct Logger : Sendable {

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
        try? AndroidLogger(tag: tag, priority: .info).log(message)
    }

    public func trace(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .verbose).log(message)
    }

    public func debug(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .debug).log(message)
    }

    public func info(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .info).log(message)
    }

    public func notice(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .info).log(message)
    }

    public func warning(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .warning).log(message)
    }

    public func error(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .error).log(message)
    }

    public func critical(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .error).log(message)
    }

    public func fault(_ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .fatal).log(message)
    }

    public func log(level type: OSLogType, _ message: OSLogMessage) {
        try? AndroidLogger(tag: tag, priority: .init(type)).log(message)
    }

    private var tag: LogTag {
        LogTag(rawValue: subsystem.isEmpty && category.isEmpty ? "" : (subsystem + "/" + category))
    }
}

public struct OSLogType: Equatable, Hashable, RawRepresentable, Sendable {

    public let rawValue: UInt8

    public init(_ rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

extension OSLogType {
    public static var `default`: OSLogType  { OSLogType(0x00) }
    public static var info: OSLogType       { OSLogType(0x01) }
    public static var debug: OSLogType      { OSLogType(0x02) }
    public static var error: OSLogType      { OSLogType(0x10) }
    public static var fault: OSLogType      { OSLogType(0x11) }
}

internal extension LogPriority {

    init(_ type: OSLogType) {
        switch type {
        case .info:
            self = .info
        case .debug:
            self = .debug
        case .error:
            self = .error
        case .fault:
            self = .fatal
        default:
            self = .default
        }
    }
}

#endif
