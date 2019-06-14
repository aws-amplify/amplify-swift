//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockLoggingCategoryPlugin: MessageReporter, LoggingCategoryPlugin {
    var key: String {
        return "MockLoggingCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func error(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func error(error: Error, file: String, function: String, line: Int) {
        notify()
    }

    func warn(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func info(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func debug(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func verbose(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }
}

class MockSecondLoggingCategoryPlugin: MockLoggingCategoryPlugin {
    override var key: String {
        return "MockSecondLoggingCategoryPlugin"
    }
}

final class MockLoggingCategoryPluginSelector: MessageReporter, LoggingPluginSelector {
    var selectedPluginKey: PluginKey? = "MockLoggingCategoryPlugin"

    func error(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func error(error: Error, file: String, function: String, line: Int) {
        notify()
    }

    func warn(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func info(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func debug(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

    func verbose(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        notify()
    }

}

class MockLoggingPluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.logging

    func makeSelector() -> PluginSelector {
        notify()
        return MockLoggingCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
