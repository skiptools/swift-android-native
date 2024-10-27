import XCTest
import AndroidOSLog // note: on non-android platforms, this will just export the system OSLog

@available(iOS 14.0, *)
class AndroidOSLogTests : XCTestCase {
    public func testOSLogAPI() {
        let emptyLogger = Logger()
        emptyLogger.info("Android logger test: empty message")

        let logger = Logger(subsystem: "AndroidOSLog", category: "test")

        logger.log("Android logger test: LOG message")

        logger.trace("Android logger test: TRACE message")
        logger.debug("Android logger test: DEBUG message")
        logger.info("Android logger test: INFO message")
        logger.notice("Android logger test: NOTICE message")
        logger.warning("Android logger test: WARNING message")
        logger.error("Android logger test: ERROR message")
        logger.critical("Android logger test: CRITICAL message")

        logger.log(level: OSLogType.default, "Android logger test: DEFAULT message")
        logger.log(level: OSLogType.info, "Android logger test: INFO message")
        logger.log(level: OSLogType.debug, "Android logger test: DEBUG message")
        logger.log(level: OSLogType.error, "Android logger test: ERROR message")
        logger.log(level: OSLogType.fault, "Android logger test: FAULT message")
    }
}
