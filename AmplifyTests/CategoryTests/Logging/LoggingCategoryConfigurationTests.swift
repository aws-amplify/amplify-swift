//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class LoggingCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddLoggingPlugin() throws {
        let plugin = MockLoggingCategoryPlugin()
        XCTAssertNoThrow(Amplify.add(plugin: plugin))
    }

    func testCanConfigureLoggingPlugin() throws {
        let plugin = MockLoggingCategoryPlugin()
        Amplify.add(plugin: plugin)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Logging)
        XCTAssertNotNil(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"))
    }

    func testCanResetLoggingPlugin() throws {
        let plugin = MockLoggingCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockLoggingCategoryPlugin()
        Amplify.add(plugin: plugin)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleLoggingPlugins() throws {
        let plugin1 = MockLoggingCategoryPlugin()
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondLoggingCategoryPlugin()
        Amplify.add(plugin: plugin2)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: [
                "MockLoggingCategoryPlugin": true,
                "MockSecondLoggingCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Logging.getPlugin(for: "MockSecondLoggingCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockLoggingCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "debug" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )
        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Logging.debug("test")

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseDefaultPluginIfMultiplePlugins() throws {
        let plugin1 = MockLoggingCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "debug" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondLoggingCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "debug" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: [
                "MockLoggingCategoryPlugin": true,
                "MockSecondLoggingCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.Logging.debug("test")
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockLoggingCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "debug" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondLoggingCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "debug" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let loggingConfig = BasicCategoryConfiguration(
            plugins: [
                "MockLoggingCategoryPlugin": true,
                "MockSecondLoggingCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Logging.getPlugin(for: "MockSecondLoggingCategoryPlugin").debug("test")
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockLoggingCategoryPlugin()
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

        let loggingConfig = BasicCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
