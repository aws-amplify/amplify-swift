//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting

@testable import Amplify

class APICategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
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

    func testCanResetAPIPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.API.getPlugin(for: "MockAPICategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testThrowsAddingSecondPluginWithNoSelector() throws {
        let plugin1 = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin2),
                             "Adding a second plugin before adding a selector should throw") { error in
                                guard case PluginError.noSelector = error else {
                                    XCTFail("Expected PluginError.noSelector")
                                    return
                                }
        }
    }

    func testDoesNotThrowAddingSecondPluginWithSelector() throws {
        let plugin1 = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.API.set(pluginSelectorFactory: MockAPIPluginSelectorFactory())

        let plugin2 = MockSecondAPICategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin2))
    }

    func testCanRegisterMultipleAPIPlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.API.set(pluginSelectorFactory: MockAPIPluginSelectorFactory())

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

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockAPICategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "get()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.API.get()

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSelectorDerivedPluginIfMultiplePlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "get()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.API.set(pluginSelectorFactory: MockAPIPluginSelectorFactory())

        let plugin2 = MockSecondAPICategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "get()" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
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
        Amplify.API.get()
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockAPICategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "get()" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.API.set(pluginSelectorFactory: MockAPIPluginSelectorFactory())

        let plugin2 = MockSecondAPICategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "get()" {
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
        try Amplify.API.getPlugin(for: "MockSecondAPICategoryPlugin").get()
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockAPICategoryPlugin()
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

        let apiConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.API.getPlugin(for: "MockAPICategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.API.get()
        }
        XCTAssertNotNil(exception)
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

    func testCanConfigureAfterReset() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        try Amplify.API.configure(using: categoryConfig)
        Amplify.API.reset()
        XCTAssertNoThrow(try Amplify.API.configure(using: categoryConfig))
    }

}
