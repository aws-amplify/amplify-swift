//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockLoggingCategoryPlugin: MessageReporter, LoggingCategoryPlugin, Logger {
    var logLevel = LogLevel.verbose

    var `default`: Logger {
        self
    }

    func logger(forCategory category: String) -> Logger {
        self
    }

    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        self
    }

    var key: String {
        return "MockLoggingCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

    func error(_ message: @autoclosure () -> String) {
        notify("\(#function): \(message())")
    }

    func error(error: Error) {
        notify("error(error:): \(error)")
    }

    func warn(_ message: @autoclosure () -> String) {
        notify("\(#function): \(message())")
    }

    func info(_ message: @autoclosure () -> String) {
        notify("\(#function): \(message())")
    }

    func debug(_ message: @autoclosure () -> String) {
        notify("\(#function): \(message())")
    }

    func verbose(_ message: @autoclosure () -> String) {
        notify("\(#function): \(message())")
    }
}

class MockSecondLoggingCategoryPlugin: MockLoggingCategoryPlugin {
    override var key: String {
        return "MockSecondLoggingCategoryPlugin"
    }
}
