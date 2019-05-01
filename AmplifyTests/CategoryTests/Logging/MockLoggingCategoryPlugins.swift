//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// A LoggingPlugin that invokes a callback when any of its methods are invoked. Note that the list of
/// notifiers are static--using this class in a parallelized test environment may produce unexpected
/// results
class MockLoggingCategoryPlugin: MessageReporter, LoggingCategoryPlugin {
    var key: PluginKey {
        return "MockLoggingCategoryPlugin"
    }

    var logLevel = LogLevel.warn

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func error(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify("error(String)")
    }

    func error(error: Error, file: String, function: String, line: Int) {
        notify("error(Error)")
    }

    func warn(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify("warn")
    }

    func info(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify("info")
    }

    func debug(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify("debug")
    }

    func verbose(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify("verbose")
    }

}

class MockSecondLoggingCategoryPlugin: MockLoggingCategoryPlugin {
    override var key: PluginKey {
        return "MockSecondLoggingCategoryPlugin"
    }
}
