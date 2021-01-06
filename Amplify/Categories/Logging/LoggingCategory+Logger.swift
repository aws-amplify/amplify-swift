//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension LoggingCategory: Logger {

    /// Logs a message at `error` level
    public func error(_ message: @autoclosure () -> String) {
        plugin.default.error(message())
    }

    /// Logs the error at `error` level
    public func error(error: Error) {
        plugin.default.error(error: error)
    }

    /// Logs a message at `warn` level
    public func warn(_ message: @autoclosure () -> String) {
        plugin.default.warn(message())
    }

    /// Logs a message at `info` level
    public func info(_ message: @autoclosure () -> String) {
        plugin.default.info(message())
    }

    /// Logs a message at `debug` level
    public func debug(_ message: @autoclosure () -> String) {
        plugin.default.debug(message())
    }

    /// Logs a message at `verbose` level
    public func verbose(_ message: @autoclosure () -> String) {
        plugin.default.verbose(message())
    }

}
