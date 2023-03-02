//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AmplifyTestCommon
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointPushNotificationsPlugin
import XCTest

class AWSPinpointPushNotificationsPluginConfigureTests: AWSPinpointPushNotificationsPluginTestBase {
    private var hubPlugin: HubCategoryPlugin {
        guard let plugin = try? Amplify.Hub.getPlugin(for: "awsHubPlugin"),
            plugin.key == "awsHubPlugin" else {
            fatalError("Could not access awsHubPlugin")
        }
        return plugin
    }

    override func setUp() async throws {
        try await super.setUp()
        AWSPinpointFactory.credentialsProvider = MockCredentialsProvider()
        AmplifyRemoteNotificationsHelper.shared = mockRemoteNotifications
    }

    override func tearDown() async throws {
        await hubPlugin.reset()
        try await super.tearDown()
    }

    // MARK: - Plugin Key tests
    func testPluginKey() {
        XCTAssertEqual(plugin.key, "awsPinpointPushNotificationsPlugin")
    }

    // MARK: Configuration tests
    func testConfigure_withValidConfiguration_shouldSucceed() {
        do {
            try plugin.configure(using: createPushNotificationsPluginConfig())
            XCTAssertNotNil(plugin.pinpoint)
            XCTAssertEqual(plugin.options, authorizationOptions)
        } catch {
            XCTFail("Failed to configure Push Notifications plugin")
        }
    }

    func testConfigure_withNotificationsPermissionsGranted_shouldRegisterForRemoteNotifications() throws {
        mockRemoteNotifications.mockedRequestAuthorizationResult = true
        mockRemoteNotifications.registerForRemoteNotificationsExpectation = expectation(description: "Permissions Granted")
        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withNotificationsPermissionsDenied_shouldRegisterForRemoteNotifications() throws {
        mockRemoteNotifications.mockedRequestAuthorizationResult = false
        mockRemoteNotifications.registerForRemoteNotificationsExpectation = expectation(description: "Permissions Denied")
        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withNotificationsPermissionsFailed_shouldRegisterForRemoteNotifications() throws {
        let error = PushNotificationsError.service("Description", "Recovery", nil)
        mockRemoteNotifications.requestAuthorizationError = error
        mockRemoteNotifications.registerForRemoteNotificationsExpectation = expectation(description: "Permissions Failed")
        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withEmptyOptions_shouldNotReportToHub() throws {
        plugin = AWSPinpointPushNotificationsPlugin(options: [])
        try plugin.configure(using: createPushNotificationsPluginConfig())
        let eventWasReported = expectation(description: "Event was reported to Hub")
        _ = hubPlugin.listen(to: .pushNotifications, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Notifications.Push.requestNotificationsPermissions {
                eventWasReported.fulfill()
            }
        }
        eventWasReported.isInverted = true
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withNotificationsPermissionsGranted_shouldReportSuccessToHub() throws {
        mockRemoteNotifications.mockedRequestAuthorizationResult = true

        let eventWasReported = expectation(description: "Event was reported to Hub")
        _ = hubPlugin.listen(to: .pushNotifications, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Notifications.Push.requestNotificationsPermissions {
                eventWasReported.fulfill()
                guard let result = payload.data as? Bool else {
                    XCTFail("Expected result")
                    return
                }

                XCTAssertTrue(result)
            }
        }

        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withNotificationsPermissionsDenied_shouldReportFailureToHub() throws {
        mockRemoteNotifications.mockedRequestAuthorizationResult = false

        let eventWasReported = expectation(description: "Event was reported to Hub")
        _ = hubPlugin.listen(to: .pushNotifications, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Notifications.Push.requestNotificationsPermissions {
                eventWasReported.fulfill()
                guard let result = payload.data as? Bool else {
                    XCTFail("Expected result")
                    return
                }

                XCTAssertFalse(result)
            }
        }

        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)
    }

    func testConfigure_withNotificationsPermissionsFailed_shouldReportErrorToHub() throws {
        let error = PushNotificationsError.service("Description", "Recovery", nil)
        mockRemoteNotifications.requestAuthorizationError = error

        let eventWasReported = expectation(description: "Event was reported to Hub")
        _ = hubPlugin.listen(to: .pushNotifications, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Notifications.Push.requestNotificationsPermissions {
                eventWasReported.fulfill()
                guard let error = payload.data as? PushNotificationsError,
                      case .service(let errorDescription, let recoverySuggestion, _) = error else {
                    XCTFail("Expected Push Notification error")
                    return
                }
                XCTAssertEqual("Description", errorDescription)
                XCTAssertEqual("Recovery", recoverySuggestion)
            }
        }

        try plugin.configure(using: createPushNotificationsPluginConfig())
        waitForExpectations(timeout: 1)

    }

    func testConfigure_withNilConfiguration_shouldThrowError() throws {
        do {
            try plugin.configure(using: nil)
            XCTFail("Push Notifications configuration should not succeed")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    private func createPushNotificationsPluginConfig() -> JSONValue {
        let appId = JSONValue(stringLiteral: testAppId)
        let region = JSONValue(stringLiteral: testRegion)

        let pinpointConfiguration = JSONValue(
            dictionaryLiteral:
                (AWSPinpointPluginConfiguration.appIdConfigKey, appId),
                (AWSPinpointPluginConfiguration.regionConfigKey, region)
        )

        return pinpointConfiguration
    }
}
