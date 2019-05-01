//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class StorageCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        XCTAssertNoThrow(Amplify.add(plugin: plugin))
    }

    func testCanConfigureStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        Amplify.add(plugin: plugin)

        let storageConfig = BasicCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.Storage)
        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"))
    }

    func testCanResetStoragePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let storageConfig = BasicCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        Amplify.add(plugin: plugin)

        let storageConfig = BasicCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

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

    func testCanRegisterMultipleStoragePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondStorageCategoryPlugin()
        Amplify.add(plugin: plugin2)

        let storageConfig = BasicCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: "MockSecondStorageCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockStorageCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "stub()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin)

        let storageConfig = BasicCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )
        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.Storage.stub()

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseDefaultPluginIfMultiplePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin1.listeners.append { message in
            if message == "stub()" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondStorageCategoryPlugin()
        let methodShouldNotBeInvokedOnSecondPlugin =
            expectation(description: "test method should not be invoked on second plugin")
        methodShouldNotBeInvokedOnSecondPlugin.isInverted = true
        plugin2.listeners.append { message in
            if message == "stub()" {
                methodShouldNotBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let storageConfig = BasicCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.Storage.stub()
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockStorageCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "stub()" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondStorageCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "stub()" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        Amplify.add(plugin: plugin2)

        let storageConfig = BasicCategoryConfiguration(
            plugins: [
                "MockStorageCategoryPlugin": true,
                "MockSecondStorageCategoryPlugin": true
            ]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Storage.getPlugin(for: "MockSecondStorageCategoryPlugin").stub()
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
        Amplify.add(plugin: plugin)

        let storageConfig = BasicCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = BasicAmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

}
