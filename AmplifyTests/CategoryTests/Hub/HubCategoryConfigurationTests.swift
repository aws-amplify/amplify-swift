//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class HubCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddHubPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        XCTAssertNoThrow(Amplify.add(plugin: plugin))
    }

    func testCanConfigureHubPlugin() throws {
        let plugin = MockHubCategoryPlugin()
        Amplify.add(plugin: plugin)

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
        Amplify.add(plugin: plugin)

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
        Amplify.add(plugin: plugin)

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

    func testCanRegisterMultipleHubPlugins() throws {
        let plugin1 = MockHubCategoryPlugin()
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondHubCategoryPlugin()
        Amplify.add(plugin: plugin2)

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
            if message == "dispatch(to:payload:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let hubConfig = BasicCategoryConfiguration(plugins: ["MockHubCategoryPlugin": true])
        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)

        let payload = BasicHubPayload()
        let channel = HubChannel.core

        Amplify.Hub.dispatch(to: channel, payload: payload)

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseDefaultPluginIfMultiplePlugins() throws {
        let plugin1 = MockHubCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondHubCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let hubConfig = BasicCategoryConfiguration(
            plugins: [
                "MockHubCategoryPlugin": true,
                "MockSecondHubCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        let payload = BasicHubPayload()
        let channel = HubChannel.core
        Amplify.Hub.dispatch(to: channel, payload: payload)
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockHubCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "stub()" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondHubCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "stub()" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let hubConfig = BasicCategoryConfiguration(
            plugins: [
                "MockHubCategoryPlugin": true,
                "MockSecondHubCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)

        let payload = BasicHubPayload()
        let channel = HubChannel.core

        try Amplify.Hub.getPlugin(for: "MockSecondHubCategoryPlugin").dispatch(to: channel, payload: payload)
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
        Amplify.add(plugin: plugin)

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Hub.getPlugin(for: "MockHubCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
