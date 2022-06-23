//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class ConfigurationTests: XCTestCase {
    override func setUp() async throws {
        await Amplify.reset()
    }

    // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
    func testPreconditionFailureInvokingWithNoPlugin() throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)

        try XCTAssertThrowFatalError {
            _ = Amplify.API.get(request: RESTRequest()) { _ in }
        }
    }

    // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        try XCTAssertThrowFatalError {
            _ = Amplify.API.get(request: RESTRequest()) { _ in }
        }
    }

    func testConfigureDelegatesToPlugins() throws {
        let configureWasInvoked = expectation(description: "Plugin configure() was invoked")
        let plugin = MockLoggingCategoryPlugin()
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                configureWasInvoked.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        wait(for: [configureWasInvoked], timeout: 1.0)
    }

    func testMultipleConfigureCallsThrowError() throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)
        XCTAssertThrowsError(try Amplify.configure(amplifyConfig),
                             "Subsequent calls to configure should throw") { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured error")
                return
            }
        }
    }

    func testResetClearsPreviouslyAddedPlugins() async throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        XCTAssertNotNil(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"))
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"),
                             "Plugins should be reset") { error in
                                guard case LoggingError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin error")
                                    return
                                }
        }
    }

    func testResetDelegatesToPlugins() async throws {
        let plugin = MockLoggingCategoryPlugin()

        let resetWasInvoked = expectation(description: "Reset was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        wait(for: [resetWasInvoked], timeout: 1.0)
    }

    func testResetAllowsReconfiguration() async throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertNoThrow(try Amplify.configure(amplifyConfig))
    }

    func testDecodeConfiguration() throws {
        let jsonString = """
        {"UserAgent":"aws-amplify-cli/2.0","Version":"1.0","storage":{"plugins":{"MockStorageCategoryPlugin":{}}}}
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let config = try decoder.decode(AmplifyConfiguration.self, from: jsonData)
        XCTAssertNotNil(config.storage)
    }
}
