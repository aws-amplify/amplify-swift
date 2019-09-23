//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting

@testable import AmplifyTestCommon

@testable import Amplify

class StorageCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Storage)
        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"))
    }

    func testCanResetStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case PluginError.noSuchPlugin = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testThrowsAddingSecondPluginWithNoSelector() throws {
        let plugin1 = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondStorageCategoryPlugin()
        XCTAssertThrowsError(try Amplify.add(plugin: plugin2),
                             "Adding a second plugin before adding a selector should throw") { error in
                                guard case PluginError.noSelector = error else {
                                    XCTFail("Expected PluginError.noSelector")
                                    return
                                }
        }
    }

    func testDoesNotThrowAddingSecondPluginWithSelector() throws {
        let plugin1 = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Storage.set(pluginSelectorFactory: MockStoragePluginSelectorFactory())

        let plugin2 = MockSecondStorageCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin2))
    }

    func testCanRegisterMultipleStoragePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        try Amplify.Storage.set(pluginSelectorFactory: MockStoragePluginSelectorFactory())

        let plugin2 = MockSecondStorageCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockSecondStorageCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "getData" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(plugins: ["MockStorageCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        _ = Amplify.Storage.getData(key: "", options: nil, onEvent: nil)

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSelectorDerivedPluginIfMultiplePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "getData" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Storage.set(pluginSelectorFactory: MockStoragePluginSelectorFactory())

        let plugin2 = MockSecondStorageCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "getData" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        _ = Amplify.Storage.getData(key: "", options: nil, onEvent: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockStorageCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "getDatab" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        try Amplify.Storage.set(pluginSelectorFactory: MockStoragePluginSelectorFactory())

        let plugin2 = MockSecondStorageCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "getData" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        _ = try Amplify.Storage.getPlugin(for: "MockSecondStorageCategoryPlugin")
            .getData(key: "", options: nil, onEvent: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockStorageCategoryPlugin()
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

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            _ = Amplify.Storage.getData(key: "foo", options: nil, onEvent: nil)
        }
        XCTAssertNotNil(exception)
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        try Amplify.Storage.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.Storage.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        try Amplify.Storage.configure(using: categoryConfig)

        let semaphore = DispatchSemaphore(value: 1)
        Amplify.Storage.reset { semaphore.signal() }
        semaphore.wait()

        XCTAssertNoThrow(try Amplify.Storage.configure(using: categoryConfig))
    }

}
