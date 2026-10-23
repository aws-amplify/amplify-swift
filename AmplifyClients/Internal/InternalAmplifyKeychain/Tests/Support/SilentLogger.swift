//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation

/// A logger that discards everything, for exercising code that requires one.
struct SilentLogger: Logger {
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
}
