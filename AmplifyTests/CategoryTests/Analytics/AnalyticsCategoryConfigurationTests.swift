//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class AnalyticsCategoryConfigurationTests: XCTestCase {
    override func setUp() async throws {
        await Amplify.reset()
    }

    func testCanAddAnalyticsPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureAnalyticsPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Analytics)
        XCTAssertNotNil(try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin"))
    }

    func testCanResetAnalyticsPlugin() async throws {
        let plugin = MockAnalyticsCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case AnalyticsError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleAnalyticsPlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Analytics.getPlugin(for: "MockSecondAnalyticsCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "record(eventWithName:test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let analyticsConfig =
            AnalyticsCategoryConfiguration(plugins: ["MockAnalyticsCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Analytics.record(eventWithName: "test")

        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        try XCTAssertThrowFatalError {
            Amplify.Analytics.record(eventWithName: "test")
        }
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "record(eventWithName:test)" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "record(eventWithName:test)" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Analytics.getPlugin(for: "MockSecondAnalyticsCategoryPlugin").record(eventWithName: "test")
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockAnalyticsCategoryPlugin()
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

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        try XCTAssertThrowFatalError {
            Amplify.Analytics.record(eventWithName: "test")
        }
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        try Amplify.Analytics.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.Analytics.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        try Amplify.Analytics.configure(using: categoryConfig)

        let exp = expectation(description: #function)
        Amplify.Analytics.reset {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        XCTAssertNoThrow(try Amplify.Analytics.configure(using: categoryConfig))
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

        let categoryConfig = AnalyticsCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: categoryConfig, logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Analytics category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: config)

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
