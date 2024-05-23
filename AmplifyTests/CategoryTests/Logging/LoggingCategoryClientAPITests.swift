//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class LoggingCategoryClientAPITests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() async throws {
        await Amplify.reset()

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(logging: loggingConfig)
    }

    // MARK: - Test passthrough delegations

    func testErrorWithString() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "error(_:) method was invoked on plugin")
        plugin.listeners.append { message in
            if message.starts(with: "error(_:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.error("Test")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    func testErrorWithError() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "error(error:) method was invoked on plugin")
        plugin.listeners.append { message in
            if message.starts(with: "error(error:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let error = ConfigurationError.amplifyAlreadyConfigured("Test", "Test")
        Amplify.Logging.error(error: error)

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    func testWarn() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "warn(_:) method was invoked on plugin")
        plugin.listeners.append { message in
            print("message: \(message)")
            if message.starts(with: "warn(_:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.warn("Test")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    func testInfo() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "info(_:) method was invoked on plugin")
        plugin.listeners.append { message in
            if message.starts(with: "info(_:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.info("Test")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    func testDebug() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "debug(_:) method was invoked on plugin")
        plugin.listeners.append { message in
            if message.starts(with: "debug(_:)") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.debug("Test")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    func testVerbose() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "verbose(_:) method was invoked on plugin")
        // Amplify uses verbose logging during the `reset` flow, so there may be mulitple
        // invocations. We'll explicitly check the message content
        plugin.listeners.append { message in
            print("message: \(message)")
            if message.starts(with: "verbose(_:)") && message.contains("Testing verbose logging") {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.verbose("Testing verbose logging")

        await fulfillment(of: [methodWasInvokedOnPlugin], timeout: 0.5)
    }

    // MARK: - Other tests

    func testAmplifyDoesNotEvaluateMessageAutoclosureForLoggingStatements() async throws {
        let plugin = NonEvaluatingLoggingPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = LoggingCategoryConfiguration(plugins: [plugin.key: true])
        let amplifyConfig = AmplifyConfiguration(logging: categoryConfig)
        try Amplify.configure(amplifyConfig)

        let messageWasEvaluated = expectation(description: "message should not be evaluated")
        messageWasEvaluated.isInverted = true
        Amplify.Logging.warn("Should not evaluate \(messageWasEvaluated.fulfill())")

        await fulfillment(of: [messageWasEvaluated], timeout: 0.5)
    }

}

// A bare class that does not forward or evaluate message autoclosure. Used to test that Amplify, as
// a framework, does not evaluate the autoclosure
class NonEvaluatingLoggingPlugin: LoggingCategoryPlugin, Logger {
    var logLevel = LogLevel.error

    let key = "NonEvaluatingLoggingPlugin"

    func configure(using configuration: Any?) throws {
        // Do nothing
    }

    var `default`: Logger {
        self
    }
    
    func enable() {
        
    }
    
    func disable() {
        
    }
    
    func logger(forNamespace namespace: String) -> Logger {
        self
    }
    
    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        self
    }

    func logger(forCategory category: String) -> Logger {
        self
    }

    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        self
    }

    func reset() {
        // Do nothing
    }

    func error(_ message: @autoclosure () -> String) {
        // Do nothing
    }

    func error(error: Error) {
        // Do nothing
    }

    func warn(_ message: @autoclosure () -> String) {
        // Do nothing
    }

    func info(_ message: @autoclosure () -> String) {
        // Do nothing
    }

    func debug(_ message: @autoclosure () -> String) {
        // Do nothing
    }

    func verbose(_ message: @autoclosure () -> String) {
        // Do nothing
    }

}
