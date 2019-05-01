//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class APICategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddAPIPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        XCTAssertNoThrow(Amplify.add(plugin: plugin))
    }

    func testCanConfigureAPIPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        Amplify.add(plugin: plugin)

        let apiConfig = BasicCategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

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
        Amplify.add(plugin: plugin)

        let apiConfig = BasicCategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockAPICategoryPlugin()
        Amplify.add(plugin: plugin)

        let apiConfig = BasicCategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

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

    func testCanRegisterMultipleAPIPlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        Amplify.add(plugin: plugin2)

        let apiConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

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
        Amplify.add(plugin: plugin)

        let apiConfig = BasicCategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.API.get()

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseDefaultPluginIfMultiplePlugins() throws {
        let plugin1 = MockAPICategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "get()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "get()" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let apiConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

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
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondAPICategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "get()" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let apiConfig = BasicCategoryConfiguration(
            plugins: [
                "MockAPICategoryPlugin": true,
                "MockSecondAPICategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

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
        Amplify.add(plugin: plugin)

        let apiConfig = BasicCategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(api: apiConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.API.getPlugin(for: "MockAPICategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
