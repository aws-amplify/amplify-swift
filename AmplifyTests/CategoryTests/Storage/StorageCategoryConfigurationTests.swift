//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class StorageCategoryConfigurationTests: XCTestCase {
    override func setUp() async throws {
        await Amplify.reset()
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

    func testCanResetStoragePlugin() async throws {
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
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.Storage.getPlugin(for: "MockStorageCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case StorageError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleStoragePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin1)

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
            if message == "downloadData" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let storageConfig = StorageCategoryConfiguration(plugins: ["MockStorageCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        try Amplify.configure(amplifyConfig)

        _ = Amplify.Storage.downloadData(key: "", options: nil, resultListener: nil)

        waitForExpectations(timeout: 1.0)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockStorageCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "downloadData" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondStorageCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "downloadData" {
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
            .downloadData(key: "", options: nil, progressListener: nil, resultListener: nil)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin1)

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

        let registry = TypeRegistry.register(type: StorageCategoryPlugin.self) { _ in
            MockStorageCategoryPlugin()
        }

        // a precondition failure will happen since 2 plugins are added
        _ = Amplify.Storage.downloadData(key: "", options: nil, resultListener: nil)

        XCTAssertGreaterThan(registry.messages.count, 0)
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
        try XCTAssertThrowFatalError {
            _ = Amplify.Storage.downloadData(key: "foo", options: nil, resultListener: nil)
        }
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

        let exp = expectation(description: #function)
        Amplify.Storage.reset {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        XCTAssertNoThrow(try Amplify.Storage.configure(using: categoryConfig))
    }

    /// Test that Amplify logs a warning if it encounters a plugin configuration key without a corresponding plugin
    ///
    /// - Given:
    ///   - A configuration with a nonexistent plugin key specified
    /// - When:
    ///    - I invoke `Amplify.configure()`
    /// - Then:
    ///    - I should see a log warning
    ///
    func testWarnsOnMissingPlugin() throws {
        let warningReceived = expectation(description: "Warning message received")

        let loggingPlugin = MockLoggingCategoryPlugin()
        loggingPlugin.listeners.append { message in
            if message.starts(with: "warn(_:): No plugin found") {
                warningReceived.fulfill()
            }
        }
        let loggingConfig = LoggingCategoryConfiguration(
            plugins: [loggingPlugin.key: true]
        )
        try Amplify.add(plugin: loggingPlugin)

        let categoryConfig = StorageCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig, storage: categoryConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Storage category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: config)

        try Amplify.configure(amplifyConfig)

        XCTAssertThrowsError(try Amplify.add(plugin: plugin),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }

    }
}
