//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import CwlPreconditionTesting

@testable import Amplify

class HubCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddHubPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureHubPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Hub)
        XCTAssertNotNil(try Amplify.Hub.getPlugin(for: "MockHubCategoryPlugin"))
    }

    func testCanResetHubPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Hub.getPlugin(for: "MockHubCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testThrowsAddingSecondPluginWithNoSelector() throws {
        let plugin1 = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondHubCategoryPlugin()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin2),
                             "Adding a second plugin before adding a selector should throw") { error in
                                guard case PluginError.noSelector = error else {
                                    XCTFail("Expected PluginError.noSelector")
                                    return
                                }
        }
    }

    func testDoesNotThrowAddingSecondPluginWithSelector() throws {
        let plugin1 = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Hub.set(pluginSelectorFactory: MockHubPluginSelectorFactory())

        let plugin2 = MockSecondHubCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin2))
    }

    func testCanRegisterMultipleHubPlugins() throws {
        let plugin1 = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Hub.set(pluginSelectorFactory: MockHubPluginSelectorFactory())

        let plugin2 = MockSecondHubCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let hubConfig = BasicCategoryConfiguration(
            plugins: [
                "MockHubCategoryPlugin": true,
                "MockSecondHubCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Hub.getPlugin(for: "MockHubCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Hub.getPlugin(for: "MockSecondHubCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockHubCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "removeListener(_:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let hubConfig =
            BasicCategoryConfiguration(plugins: ["MockHubCategoryPlugin": true])
        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Hub.removeListener(UUID())

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSelectorDerivedPluginIfMultiplePlugins() throws {
        let plugin1 = MockHubCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "removeListener(_:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Hub.set(pluginSelectorFactory: MockHubPluginSelectorFactory())

        let plugin2 = MockSecondHubCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "removeListener(_:)" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let hubConfig = BasicCategoryConfiguration(
            plugins: [
                "MockHubCategoryPlugin": true,
                "MockSecondHubCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.Hub.removeListener(UUID())
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockHubCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "removeListener(_:)" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Hub.set(pluginSelectorFactory: MockHubPluginSelectorFactory())

        let plugin2 = MockSecondHubCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "removeListener(_:)" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let hubConfig = BasicCategoryConfiguration(
            plugins: [
                "MockHubCategoryPlugin": true,
                "MockSecondHubCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Hub.getPlugin(for: "MockSecondHubCategoryPlugin").removeListener(UUID())
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockHubCategoryPlugin()
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

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Hub.getPlugin(for: "MockHubCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.Hub.dispatch(to: HubChannel.core, payload: HubPayload(event: "foo"))
        }
        XCTAssertNotNil(exception)
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        try Amplify.Hub.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.Hub.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        try Amplify.Hub.configure(using: categoryConfig)
        Amplify.Hub.reset()
        XCTAssertNoThrow(try Amplify.Hub.configure(using: categoryConfig))
    }

}
