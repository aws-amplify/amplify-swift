//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

@testable import AmplifyTestCommon

class LoggingCategoryClientAPITests: XCTestCase {
    var mockAmplifyConfig: AmplifyConfiguration!

    override func setUp() {
        Amplify.reset()

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        mockAmplifyConfig = AmplifyConfiguration(logging: loggingConfig)
    }

    // MARK: - Test passthrough delegations

    func testErrorWithString() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "error(_:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.error("Test")

        waitForExpectations(timeout: 0.5)
    }

    func testErrorWithError() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "error(error:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let error = ConfigurationError.amplifyAlreadyConfigured("Test", "Test")
        Amplify.Logging.error(error: error)

        waitForExpectations(timeout: 0.5)
    }

    func testWarn() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "warn(_:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.warn("Test")

        waitForExpectations(timeout: 0.5)
    }

    func testInfo() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "info(_:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.info("Test")

        waitForExpectations(timeout: 0.5)
    }

    func testDebug() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "debug(_:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.debug("Test")

        waitForExpectations(timeout: 0.5)
    }

    func testVerbose() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        plugin.listeners.append { message in
            if message == "verbose(_:file:function:line:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        Amplify.Logging.verbose("Test")

        waitForExpectations(timeout: 0.5)
    }

    // MARK: - Other tests

    func testAmplifyDoesNotEvaluateMessageAutoclosureForLoggingStatements() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let messageWasEvaluated = expectation(description: "message should not be evaluated")
        messageWasEvaluated.isInverted = true
        Amplify.Logging.warn("Should not evaluate \(messageWasEvaluated.fulfill())")

        waitForExpectations(timeout: 0.5)
    }

    func testAmplifyDoesNotEvaluateMessageAutoclosureForNonLoggingStatements() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)

        let messageWasEvaluated = expectation(description: "message should not be evaluated")
        messageWasEvaluated.isInverted = true
        Amplify.Logging.info("Should not evaluate \(messageWasEvaluated.fulfill())")

        waitForExpectations(timeout: 0.5)
    }

}
