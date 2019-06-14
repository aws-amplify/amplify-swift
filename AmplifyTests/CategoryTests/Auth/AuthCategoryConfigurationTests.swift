//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import CwlPreconditionTesting

class AuthCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddAuthPlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureAuthPlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let authConfig = BasicCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Auth)
        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"))
    }

    func testCanResetAuthPlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let authConfig = BasicCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let authConfig = BasicCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testThrowsAddingSecondPluginWithNoSelector() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAuthCategoryPlugin()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin2),
                             "Adding a second plugin before adding a selector should throw") { error in
                                guard case PluginError.noSelector = error else {
                                    XCTFail("Expected PluginError.noSelector")
                                    return
                                }
        }
    }

    func testDoesNotThrowAddingSecondPluginWithSelector() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Auth.set(pluginSelectorFactory: MockAuthPluginSelectorFactory())

        let plugin2 = MockSecondAuthCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin2))
    }

    func testCanRegisterMultipleAuthPlugins() throws {
        let plugin1 = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Auth.set(pluginSelectorFactory: MockAuthPluginSelectorFactory())

        let plugin2 = MockSecondAuthCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let authConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Auth.getPlugin(for: "MockSecondAuthCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockAuthCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "stub()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let authConfig =
            BasicCategoryConfiguration(plugins: ["MockAuthCategoryPlugin": true])
        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Auth.stub()

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSelectorDerivedPluginIfMultiplePlugins() throws {
        let plugin1 = MockAuthCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "stub()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Auth.set(pluginSelectorFactory: MockAuthPluginSelectorFactory())

        let plugin2 = MockSecondAuthCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "stub()" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let authConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.Auth.stub()
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockAuthCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "stub()" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Auth.set(pluginSelectorFactory: MockAuthPluginSelectorFactory())

        let plugin2 = MockSecondAuthCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "stub()" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let authConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAuthCategoryPlugin": true,
                "MockSecondAuthCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Auth.getPlugin(for: "MockSecondAuthCategoryPlugin").stub()
        waitForExpectations(timeout: 1.0)
    }

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

        let authConfig = BasicCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(auth: authConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Auth.getPlugin(for: "MockAuthCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
