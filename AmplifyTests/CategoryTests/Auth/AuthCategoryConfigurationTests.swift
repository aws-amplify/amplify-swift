//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class AuthCategoryConfigurationTests: XCTestCase {

    override func setUp() async throws {
        await Amplify.reset()
    }

    /// Test if we can add a new auth plugin
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I add a new Auth plugin to Amplify
    /// - Then:
    ///    - Plugin should be added  without throwing any error
    ///
    func testCanAddPlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    /// Test if Auth plugin can be configured
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I add a new Auth plugin and add configuration for the plugin
    /// - Then:
    ///    - Auth plugin should be configured correctly
    ///
    func testCanConfigureCategory() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Auth)
        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"))
    }

    /// Test if resetting Auth category works
    ///
    /// - Given: Amplify framework configured with Auth plugin
    /// - When:
    ///    - I call await Amplify.reset()
    /// - Then:
    ///    - The plugin should invoke the reset method.
    ///
    func testCanResetCategory() async throws {
        let plugin = MockAuthCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    /// Test whether calling reset removes the plugin added
    ///
    /// - Given: Amplify framework configured with Auth plugin
    /// - When:
    ///    - I call Amplify.reset
    /// - Then:
    ///    - Auth plugin should no longer work
    ///
    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case AuthError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    /// Test if we can register multiple plugins
    ///
    /// - Given: UnConfigured Amplify framework
    /// - When:
    ///    - I configure Amplify with multiple plugins for Auth
    /// - Then:
    ///    - I should be able to access individual plugins I added.
    ///
    func testCanRegisterMultiplePlugins() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAuthCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let config = AuthCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockSecondAuthCategoryPlugin"))
    }

    /// Test if the default plugin works
    ///
    /// - Given: Amplify configured with Auth plugin
    /// - When:
    ///    - I invoke a API from Auth plugin with default invocation
    /// - Then:
    ///    - API should complete without error
    ///
    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "changePassword" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(plugins: ["MockAuthCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)

        _ = Amplify.Auth.update(oldPassword: "current", to: "new", listener: nil)
        waitForExpectations(timeout: 1.0)
    }

    /// Test if I can pick a specific plugin
    ///
    /// - Given: Amplify configured with multiple Auth plugins
    /// - When:
    ///    - I choose one plugin and call one of the Auth API
    /// - Then:
    ///    - API should complete without error for one plugin
    ///
    func testCanUseSpecifiedPlugin() throws {
        let defaultPlugin = MockAuthCategoryPlugin()
        defaultPlugin.listeners.append { message in
            if message == "changePassword" {
                XCTFail("test method should not be invoked on default plugin")
            }
        }
        try Amplify.add(plugin: defaultPlugin)

        let anotherPlugin = MockSecondAuthCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        anotherPlugin.listeners.append { message in
            if message == "changePassword" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: anotherPlugin)

        let config = AuthCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)
        _ = try Amplify.Auth.getPlugin(for: "MockSecondAuthCategoryPlugin")
            .update(oldPassword: "current", to: "new", options: nil, listener: nil)
        waitForExpectations(timeout: 1.0)
    }

    /// Test if we get error when trying default plugin when multiple plugin added.
    ///
    /// - Given: Amplify configured with multiple auth plugin
    /// - When:
    ///    - I try to invoke an API with default plugin
    /// - Then:
    ///    - Should throw an exception
    ///
    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAuthCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let config = AuthCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)

        let registry = TypeRegistry.register(type: AuthCategoryPlugin.self) { _ in
            MockAuthCategoryPlugin()
        }

        _ = Amplify.Auth.update(oldPassword: "current", to: "new", listener: nil)

        XCTAssertGreaterThan(registry.messages.count, 0)
    }

    /// Test if configuration Auth plugin with getPlugin() works
    ///
    /// - Given: Amplify with Auth plugin configured
    /// - When:
    ///    - I try to add a new configuration to the same plugin
    /// - Then:
    ///    - Should work without any error.
    ///
    func testCanConfigurePluginDirectly() throws {
        let plugin = MockAuthCategoryPlugin()
        let configureShouldBeInvokedFromCategory =
            expectation(description: "Configure should be invoked by Amplify.configure()")
        let configureShouldBeInvokedDirectly =
            expectation(description: "Configure should be invoked by getPlugin().configure()")

        var invocationCount = 0
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                invocationCount += 1
                switch invocationCount {
                case 1: configureShouldBeInvokedFromCategory.fulfill()
                case 2: configureShouldBeInvokedDirectly.fulfill()
                default: XCTFail("Expected configure() to be called only two times, but got \(invocationCount)")
                }
            }
        }
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

        try Amplify.configure(amplifyConfig)
        try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    /// Test if unconfigured plugin throws an error
    ///
    /// - Given: An unconfigured Amplify framework with Auth plugin added
    /// - When:
    ///    - Invoke an API in auth
    /// - Then:
    ///    - I should get an exception
    ///
    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let registry = TypeRegistry.register(type: AuthCategoryPlugin.self) { _ in
            MockAuthCategoryPlugin()
        }

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        _ = Amplify.Auth.update(oldPassword: "current", to: "new", listener: nil)

        XCTAssertGreaterThan(registry.messages.count, 0)
    }

    // MARK: - Test internal config behavior guarantees

    /// Test if configuring twice throws an exception
    ///
    /// - Given: Amplify with Auth plugin configured
    /// - When:
    ///    - I try to configure Auth again
    /// - Then:
    ///    - Should throw an exception
    ///
    func testThrowsConfiguringTwice() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        XCTAssertNoThrow(try Amplify.Auth.configure(using: config))
        XCTAssertThrowsError(try Amplify.Auth.configure(using: config),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }

    }

    /// Test if configuring after reset works
    ///
    /// - Given: Amplify framework with Auth configured
    /// - When:
    ///    - I reset Amplify and then configure again
    /// - Then:
    ///    - Should not throw any error
    ///
    func testCanConfigureAfterReset() async throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        XCTAssertNoThrow(try Amplify.Auth.configure(using: config))

        await Amplify.Auth.reset()

        XCTAssertNoThrow(try Amplify.Auth.configure(using: config))

        let registry = TypeRegistry.register(type: AuthCategoryPlugin.self) { _ in
            MockAuthCategoryPlugin()
        }

        _ = Amplify.Auth.update(oldPassword: "current", to: "new", listener: nil)

        XCTAssertEqual(registry.messages.count, 0)
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

        let categoryConfig = AuthCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig, logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test that Amplify throws an `AuthError` if it encounters a plugin without a key
    ///
    /// - Given: Unconfigured Amplify Framework
    /// - When:
    ///     - I add an Auth plugin without a key
    /// - Then:
    ///     - An `AuthError` is thrown
    ///
    func testThrowsPluginWithoutKey() {
        let plugin = MockAuthCategoryPluginWithoutKey()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin)) { error in
            XCTAssertNotNil(error as? AuthError)
        }
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Auth category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: config)

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
