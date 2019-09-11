//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting

@testable import Amplify
@testable import AmplifyTestCommon

class AnalyticsCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
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

    func testCanResetAnalyticsPlugin() throws {
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
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testThrowsAddingSecondPluginWithNoSelector() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin2),
                             "Adding a second plugin before adding a selector should throw") { error in
                                guard case PluginError.noSelector = error else {
                                    XCTFail("Expected PluginError.noSelector")
                                    return
                                }
        }
    }

    func testDoesNotThrowAddingSecondPluginWithSelector() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Analytics.set(pluginSelectorFactory: MockAnalyticsPluginSelectorFactory())

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin2))
    }

    func testCanRegisterMultipleAnalyticsPlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Analytics.set(pluginSelectorFactory: MockAnalyticsPluginSelectorFactory())

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
            if message == "record(test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let analyticsConfig =
            AnalyticsCategoryConfiguration(plugins: ["MockAnalyticsCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Analytics.record("test")

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSelectorDerivedPluginIfMultiplePlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "record(test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Analytics.set(pluginSelectorFactory: MockAnalyticsPluginSelectorFactory())

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "record(test)" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
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
        Amplify.Analytics.record("test")
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "record(test)" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Analytics.set(pluginSelectorFactory: MockAnalyticsPluginSelectorFactory())

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "record(test)" {
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
        try Amplify.Analytics.getPlugin(for: "MockSecondAnalyticsCategoryPlugin").record("test")
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
        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.Analytics.record("test")
        }
        XCTAssertNotNil(exception)
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

        let semaphore = DispatchSemaphore(value: 1)
        Amplify.Analytics.reset { semaphore.signal() }
        semaphore.wait()

        XCTAssertNoThrow(try Amplify.Analytics.configure(using: categoryConfig))
    }

}
