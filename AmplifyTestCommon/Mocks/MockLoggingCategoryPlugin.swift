//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockLoggingCategoryPlugin: MessageReporter, LoggingCategoryPlugin, Logger, @unchecked Sendable {
    var logLevel = LogLevel.verbose

    var `default`: Logger {
        self
    }

    func logger(forCategory category: String) -> Logger {
        self
    }

    func logger(forNamespace namespace: String) -> Logger {
        self
    }

    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        self
    }

    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        self
    }

    func enable() {
        notify("enable")
    }

    func disable() {
        notify("disable")
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

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondLoggingCategoryPlugin: MockLoggingCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondLoggingCategoryPlugin"
    }
}
