//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class APICategoryConfigurationTests: XCTestCase {
    override func setUp() async throws {
        await Amplify.reset()
    }

    func testCanAddAPIPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureAPIPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.API)
        XCTAssertNotNil(try Amplify.API.getPlugin(for: "MockAPICategoryPlugin"))
    }

    func testCanResetAPIPlugin() async throws {
        let plugin = MockAPICategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.API.getPlugin(for: "MockAPICategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case APIError.invalidConfiguration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleAPIPlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let apiConfig = APICategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.API.getPlugin(for: "MockAPICategoryPlugin"))
        XCTAssertNotNil(try Amplify.API.getPlugin(for: "MockSecondAPICategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() async throws {
        let plugin = MockAPICategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "get" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)

        let getCompleted = asyncExpectation(description: "get completed")
        Task {
            _ = try await Amplify.API.get(request: RESTRequest())
            await getCompleted.fulfill()
        }
        await waitForExpectations([getCompleted], timeout: 0.5)

        await waitForExpectations(timeout: 1.0)
    }

    // TODO: this test is disabled for now since `catchBadInstruction` only takes in closure
    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let APIConfig = APICategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(api: APIConfig)

        try Amplify.configure(amplifyConfig)
        throw XCTSkip("this test is disabled for now since `catchBadInstruction` only takes in closure")
//        try XCTAssertThrowFatalError {
//            Task {
//                _ = try await Amplify.API.get(request: RESTRequest())
//            }
//        }
    }

    func testCanUseSpecifiedPlugin() async throws {
        let plugin1 = MockAPICategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "get" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "get" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let apiConfig = APICategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        
        let getCompleted = asyncExpectation(description: "get completed")
        Task {
            let plugin = try Amplify.API.getPlugin(for: "MockSecondAPICategoryPlugin")
            _ = try await plugin.get(request: RESTRequest())
            await getCompleted.fulfill()
        }
        await waitForExpectations([getCompleted], timeout: 0.5)

        await waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockAPICategoryPlugin()
        let configureShouldBeInvokedFromCategory =
            expectation(description: "Configure should be invoked by Amplify.configure()")
        let configureShouldBeInvokedDirectly =
            expectation(description: "Configure should be invoked by getPlugin().configure()")

        var invocationCount = 0
        plugin.listeners.append { message in
            if message == "configure" {
                invocationCount += 1
                switch invocationCount {
                case 1: configureShouldBeInvokedFromCategory.fulfill()
                case 2: configureShouldBeInvokedDirectly.fulfill()
                default: XCTFail("Expected configure() to be called only two times, but got \(invocationCount)")
                }
            }
        }
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.API.getPlugin(for: "MockAPICategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    // TODO: this test is disabled for now since `catchBadInstruction` only takes in closure
    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        throw XCTSkip("this test is disabled for now since `catchBadInstruction` only takes in closure")
//        try XCTAssertThrowFatalError {
//            Task {
//                _ = try await Amplify.API.get(request: RESTRequest())
//            }
//        }
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        try Amplify.API.configure(using: categoryConfig)

        XCTAssertThrowsError(try Amplify.API.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() async throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        try Amplify.API.configure(using: categoryConfig)

        await Amplify.API.reset()

        XCTAssertNoThrow(try Amplify.API.configure(using: categoryConfig))
    }

    func testIsConfiguredIsFalseBeforeConfig() {
        XCTAssertFalse(Amplify.API.isConfigured)
    }

    func testIsConfiguredIsTrueAfterConfig() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: categoryConfig)
        try Amplify.configure(amplifyConfig)

        XCTAssertTrue(Amplify.API.isConfigured)
    }

    func testIsConfiguredIsFalseAfterReset() async throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: categoryConfig)
        try Amplify.configure(amplifyConfig)

        await Amplify.reset()

        XCTAssertFalse(Amplify.API.isConfigured)
    }

    /// Test that Amplify logs a warning if it encounters a plugin configuration key without a corresponding plugin
    ///
    /// - Given:
    ///   - A configuration with a nonexistent plugin key specified
    /// - When:
    ///    - I invoke `Amplify.configure()`
    /// - Then:
    ///    - I should see a log warning
    ///
    func testWarnsOnMissingPlugin() throws {
        let warningReceived = expectation(description: "Warning message received")

        let loggingPlugin = MockLoggingCategoryPlugin()
        loggingPlugin.listeners.append { message in
            if message.starts(with: "warn(_:): No plugin found") {
                warningReceived.fulfill()
            }
        }
        let loggingConfig = LoggingCategoryConfiguration(
            plugins: [loggingPlugin.key: true]
        )
        try Amplify.add(plugin: loggingPlugin)

        let categoryConfig = APICategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: categoryConfig, logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for API category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertThrowsError(try Amplify.add(plugin: plugin),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }

    }
}
