//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class GeoCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddGeoPlugin() throws {
        let plugin = MockGeoCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureGeoPlugin() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let geoConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Geo)
        XCTAssertNotNil(try Amplify.Geo.getPlugin(for: "MockGeoCategoryPlugin"))
    }

    func testCanResetGeoPlugin() throws {
        let plugin = MockGeoCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let geoConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let geoConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Geo.getPlugin(for: "MockGeoCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
            guard case Geo.Error.invalidConfiguration = error else {
                XCTFail("Expected PluginError.noSuchPlugin")
                return
            }
        }
    }

    func testCanRegisterMultipleGeoPlugins() throws {
        let plugin1 = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondGeoCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let geoConfig = GeoCategoryConfiguration(
            plugins: [
                "MockGeoCategoryPlugin": true,
                "MockSecondGeoCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Geo.getPlugin(for: "MockGeoCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Geo.getPlugin(for: "MockSecondGeoCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockGeoCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "search(for text:test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let geoConfig =
            GeoCategoryConfiguration(plugins: ["MockGeoCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Geo.search(for: "test", options: nil) { _ in }

        waitForExpectations(timeout: 1.0)
    }

    // TODO: Update the unit test to work with `CwlPreconditionTesting`
    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondGeoCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let geoConfig = GeoCategoryConfiguration(
            plugins: [
                "MockGeoCategoryPlugin": true,
                "MockSecondGeoCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)

        throw XCTSkip("CwlPreconditionTesting is not compatible with async methods")
        try XCTAssertThrowFatalError {
            Amplify.Geo.search(for: "test", options: nil) { _ in }
        }
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockGeoCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "search(for text:test)" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondGeoCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "search(for text:test)" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let geoConfig = GeoCategoryConfiguration(
            plugins: [
                "MockGeoCategoryPlugin": true,
                "MockSecondGeoCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Geo.getPlugin(for: "MockSecondGeoCategoryPlugin")
            .search(for: "test", options: nil) { _ in }
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockGeoCategoryPlugin()
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

        let geoConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: geoConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Geo.getPlugin(for: "MockGeoCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    // TODO: Update the unit test to work with `CwlPreconditionTesting`
    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)

        throw XCTSkip("CwlPreconditionTesting is not compatible with async methods")
        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        try XCTAssertThrowFatalError {
            Amplify.Geo.search(for: "test", options: nil) { _ in }
        }
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        try Amplify.Geo.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.Geo.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        try Amplify.Geo.configure(using: categoryConfig)

        let exp = expectation(description: #function)
        Amplify.Geo.reset {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        XCTAssertNoThrow(try Amplify.Geo.configure(using: categoryConfig))
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

        let categoryConfig = GeoCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: categoryConfig, logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Geo category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockGeoCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = GeoCategoryConfiguration(
            plugins: ["MockGeoCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(geo: config)

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
