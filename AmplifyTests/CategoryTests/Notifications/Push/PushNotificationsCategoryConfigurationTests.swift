//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
import XCTest

class PushNotificationsCategoryConfigurationTests: XCTestCase {
    // MARK: - Setup methods

    override func setUp() async throws {
        await Amplify.reset()
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    private func createCategoryConfig(hasSecondPlugin: Bool = false) -> NotificationsCategoryConfiguration {
        var plugins: [String: JSONValue] = [
            "MockPushNotificationsCategoryPlugin": true
        ]
        if hasSecondPlugin {
            plugins["MockSecondPushNotificationsCategoryPlugin"] = true
        }

        return NotificationsCategoryConfiguration(
            plugins: plugins
        )
    }

    private func createAmplifyConfig(hasSecondPlugin: Bool = false) -> AmplifyConfiguration {
        let categoryConfiguration = createCategoryConfig(hasSecondPlugin: hasSecondPlugin)
        
        return AmplifyConfiguration(notifications: categoryConfiguration)
    }

    // MARK: - Amplify tests

    func testAddPlugin_shouldSucceed() throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testAddPlugin_afterConfigure_shouldThrowError() throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(createAmplifyConfig())

        XCTAssertThrowsError(try Amplify.add(plugin: plugin),
                             "configure() an already configured plugin should throw") { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                return
            }
        }
    }

    func testConfigure_withAlreadyConfiguredPlugin_shouldThrowError() throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = createCategoryConfig()
        try Amplify.Notifications.Push.configure(using: categoryConfig)

        XCTAssertThrowsError(try Amplify.Notifications.Push.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                return
            }
        }
    }

    func testConfigure_afterCallingReset_shouldSucceed() async throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = createCategoryConfig()

        try Amplify.Notifications.Push.configure(using: categoryConfig)
        await Amplify.Notifications.Push.reset()

        XCTAssertNoThrow(try Amplify.Notifications.Push.configure(using: categoryConfig))
    }

    func testConfigure_withConfigurationUsingMissingPlugin_shouldLogWarning() throws {
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

        let categoryConfig = NotificationsCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig, notifications: categoryConfig)
        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 0.1)
    }

    func testReset_shouldSucceed() async throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset()" {
                resetWasInvoked.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)
        try Amplify.configure(createAmplifyConfig())

        await Amplify.reset()
        await fulfillment(of: [resetWasInvoked], timeout: 1.0)
    }

    // MARK: - Category tests

    func testUsingCategory_withConfiguredPlugin_shouldSucceed() async throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "identifyUser(userId:test)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)
        try Amplify.configure(createAmplifyConfig())

        try await Amplify.Notifications.Push.identifyUser(userId: "test")
        await fulfillment(of: [methodInvokedOnDefaultPlugin], timeout: 1.0)
    }

    func testUsingCategory_withMultiplePlugins_shouldThrowFatalError() async throws {
        let plugin1 = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        try Amplify.configure(createAmplifyConfig(hasSecondPlugin: true))

        let registry = TypeRegistry.register(type: PushNotificationsCategoryPlugin.self) { _ in
            MockPushNotificationsCategoryPlugin()
        }

        try await Amplify.Notifications.Push.identifyUser(userId: "test")
        XCTAssertEqual(registry.messages.count, 1)
    }

    func testUsingCategory_withoutCallingConfigure_shouldThrowFatalError() async throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let registry = TypeRegistry.register(type: PushNotificationsCategoryPlugin.self) { _ in
            MockPushNotificationsCategoryPlugin()
        }

        try await Amplify.Notifications.Push.identifyUser(userId: "test")
        XCTAssertEqual(registry.messages.count, 1)
    }

    // MARK: - Plugin tests

    func testGetPlugin_shouldSucceed() throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(createAmplifyConfig())

        XCTAssertNotNil(try Amplify.Notifications.Push.getPlugin(for: "MockPushNotificationsCategoryPlugin"))
    }

    func testGetPlugin_afterReset_shouldThrowError() async throws {
        let plugin = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(createAmplifyConfig())

        await Amplify.reset()
        XCTAssertThrowsError(try Amplify.Notifications.Push.getPlugin(for: "MockPushNotificationsCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
            guard case PushNotificationsError.configuration = error else {
                XCTFail("Expected PushNotificationsError.configuration error")
                return
            }
        }
    }

    func testGetPlugin_withMultiplePlugins_shouldSucceed() throws {
        let plugin1 = MockPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondPushNotificationsCategoryPlugin()
        try Amplify.add(plugin: plugin2)
        try Amplify.configure(createAmplifyConfig(hasSecondPlugin: true))

        XCTAssertNotNil(try Amplify.Notifications.Push.getPlugin(for: "MockPushNotificationsCategoryPlugin"))
        XCTAssertNotNil(try Amplify.Notifications.Push.getPlugin(for: "MockPushNotificationsCategoryPlugin"))
    }
    
    func testUsingPlugin_withMultiplePlugins_shouldSucceed() async throws {
        let plugin1 = MockPushNotificationsCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
        expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "identifyUser(userId:test)" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)
        
        let plugin2 = MockSecondPushNotificationsCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
        expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "identifyUser(userId:test)" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        try Amplify.configure(createAmplifyConfig(hasSecondPlugin: true))

        try await Amplify.Notifications.Push.getPlugin(for: "MockSecondPushNotificationsCategoryPlugin").identifyUser(userId: "test", userProfile: nil)
        await fulfillment(of: [methodShouldNotBeInvokedOnDefaultPlugin, methodShouldBeInvokedOnSecondPlugin], timeout: 1.0)
    }

    func testUsingPlugin_callingConfigure_shouldSucceed() throws {
        let plugin = MockPushNotificationsCategoryPlugin()
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
        try Amplify.configure(createAmplifyConfig())

        try Amplify.Notifications.Push.getPlugin(for: "MockPushNotificationsCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }
}
