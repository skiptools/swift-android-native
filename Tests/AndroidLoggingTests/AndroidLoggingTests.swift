//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftAndroidNative open source project
//
// Copyright (c) 2024-2026 Skip.dev and SwiftAndroidNative project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftAndroidNative project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing
import AndroidLogging // note: on non-android platforms, this will just export the system OSLog

struct AndroidLoggingTests {
    @Test func testOSLogAPI() {
        let emptyLogger = Logger()
        emptyLogger.info("Android logger test: empty message")

        let logger = Logger(subsystem: "AndroidLoggingTests", category: "test")

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
