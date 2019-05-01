//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class AnalyticsCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddAnalyticsPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        XCTAssertNoThrow(Amplify.add(plugin: plugin))
    }

    func testCanConfigureAnalyticsPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        Amplify.add(plugin: plugin)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Analytics)
        XCTAssertNotNil(try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin"))
    }

    func testCanResetAnalyticsPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockAnalyticsCategoryPlugin()
        Amplify.add(plugin: plugin)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

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

    func testCanRegisterMultipleAnalyticsPlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        Amplify.add(plugin: plugin2)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

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
        Amplify.add(plugin: plugin)

        let analyticsConfig =
            BasicCategoryConfiguration(plugins: ["MockAnalyticsCategoryPlugin": true])
        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Analytics.record("test")

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseDefaultPluginIfMultiplePlugins() throws {
        let plugin1 = MockAnalyticsCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "record(test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "record(test)" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

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
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAnalyticsCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "record(test)" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAnalyticsCategoryPlugin": true,
                "MockSecondAnalyticsCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

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
        Amplify.add(plugin: plugin)

        let analyticsConfig = BasicCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(analytics: analyticsConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Analytics.getPlugin(for: "MockAnalyticsCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
