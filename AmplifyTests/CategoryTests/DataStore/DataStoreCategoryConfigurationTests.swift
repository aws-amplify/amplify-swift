//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class DataStoreCategoryConfigurationTests: XCTestCase {
    override func setUp() async throws {
        await Amplify.reset()
    }

    func testCanAddDataStorePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureFirstWithEmptyConfiguration() throws {
        let plugin = MockDataStoreCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.DataStore)
        XCTAssertNotNil(Amplify.DataStore.plugin)
        wait(for: [methodInvokedOnDefaultPlugin], timeout: 1.0)
    }

    func testCanConfigureDataStorePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.DataStore)
        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"))
    }

    func testCanResetDataStorePlugin() async throws {
        let plugin = MockDataStoreCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        await waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() async throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case DataStoreError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleDataStorePlugins() throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"))
        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockSecondDataStoreCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() async throws {
        let plugin = MockDataStoreCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "save" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: ["MockDataStoreCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        let saveSuccess = asyncExpectation(description: "save successful")
        Task {
            _ = try await Amplify.DataStore.save(TestModel.make())
            await saveSuccess.fulfill()
        }
        await waitForExpectations([saveSuccess], timeout: 1.0)
        

        await waitForExpectations(timeout: 1.0)
    }

    // TODO: this test is disabled for now since `catchBadInstruction` only takes in closure
    func testPreconditionFailureInvokingWithMultiplePlugins() async throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        throw XCTSkip("this test is disabled for now since `catchBadInstruction` only takes in closure")
//        try XCTAssertThrowFatalError {
//            Task {
//                try await Amplify.DataStore.save(TestModel.make())
//            }
//        }
    }

    func testCanUseSpecifiedPlugin() async throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "save" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "save" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        
        let saveSuccess = asyncExpectation(description: "save success")
        Task {
            _ = try await Amplify.DataStore.getPlugin(for: "MockSecondDataStoreCategoryPlugin")
                .save(TestModel.make(), where: nil)
            await saveSuccess.fulfill()
        }
        await waitForExpectations([saveSuccess], timeout: 1.0)
        
        await waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockDataStoreCategoryPlugin()
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

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    // TODO: this test is disabled for now since `catchBadInstruction` only takes in closure
    func testPreconditionFailureInvokingBeforeConfig() async throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        throw XCTSkip("this test is disabled for now since `catchBadInstruction` only takes in closure")
//        try XCTAssertThrowFatalError {
//            Task {
//                _ = try await Amplify.DataStore.save(TestModel.make())
//            }
//        }
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        try Amplify.DataStore.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.DataStore.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() async throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        try Amplify.DataStore.configure(using: categoryConfig)

        await Amplify.DataStore.reset()

        XCTAssertNoThrow(try Amplify.DataStore.configure(using: categoryConfig))
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

        let categoryConfig = DataStoreCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: categoryConfig, logging: loggingConfig)

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    /// Test if adding a plugin after configuration throws an error
    ///
    /// - Given: Amplify is configured
    /// - When:
    ///    - Add  is called for Datastore category
    /// - Then:
    ///    - Should throw an exception
    ///
    func testAddAfterConfigureThrowsError() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let config = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: config)

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
