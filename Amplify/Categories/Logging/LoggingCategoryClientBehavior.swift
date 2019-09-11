//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol LoggingCategoryClientBehavior {
    /// Logs a message at `error` level
    func error(_ message: @autoclosure () -> String, file: String, function: String, line: Int)

    /// Logs the error at `error` level
    func error(error: Error, file: String, function: String, line: Int)

    /// Logs a message at `warn` level
    func warn(_ message: @autoclosure () -> String, file: String, function: String, line: Int)

    /// Logs a message at `info` level
    func info(_ message: @autoclosure () -> String, file: String, function: String, line: Int)

    /// Logs a message at `debug` level
    func debug(_ message: @autoclosure () -> String, file: String, function: String, line: Int)

    /// Logs a message at `verbose` level
    func verbose(_ message: @autoclosure () -> String, file: String, function: String, line: Int)
}
