//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class PersistentLogWrapper: Logger {
    var logLevel: LogLevel

    var wrapper: Logger
    var logs: String?

    init(logWrapper: Logger) {
        self.wrapper = logWrapper
        self.logs = ""
        self.logLevel = logWrapper.logLevel
    }

    func error(_ message: @autoclosure () -> String) {
        // save in logs
        wrapper.error(message())
    }

    func warn(_ message: @autoclosure () -> String) {
        // save in logs
        wrapper.warn(message())
    }

    func error(error: Error) {
        // save in logs
        wrapper.error(error: error)
    }

    func info(_ message: @autoclosure () -> String) {
        // save in logs
        wrapper.info(message())
    }

    func debug(_ message: @autoclosure () -> String) {
        // save in logs
        wrapper.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String) {
        // save in logs
        wrapper.verbose(message())
    }

}
