//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AmplifyTestCommon
import UserNotifications
import XCTest

class PushNotificationsCategoryClientAPITests: XCTestCase {
    private var category: PushNotificationsCategory!
    private var plugin: MockPushNotificationsCategoryPlugin!

    override func setUp() async throws {
        await Amplify.reset()
        category = Amplify.Notifications.Push
        plugin = MockPushNotificationsCategoryPlugin()
        
        let categoryConfiguration = NotificationsCategoryConfiguration(
            plugins: ["MockPushNotificationsCategoryPlugin": true]
        )
        
        let amplifyConfiguration = AmplifyConfiguration(notifications: categoryConfiguration)
        try Amplify.add(plugin: plugin)
        try Amplify.configure(amplifyConfiguration)
    }

    override func tearDown() async throws {
        await Amplify.reset()
        category = nil
        plugin = nil
    }

    func testIdentifyUser_shouldSucceed() async throws {
        let expectedMessage = "identifyUser(userId:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        try await category.identifyUser(userId: "test")
        await waitForExpectations(timeout: 1.0)
    }

    func testRegisterDeviceToken_shouldSucceed() async throws {
        let data = "Data".data(using: .utf8)!
        let expectedMessage = "registerDevice(token:\(data))"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        try await category.registerDevice(apnsToken: data)
        await waitForExpectations(timeout: 1.0)
    }

    func testRecordNotificationReceived_shouldSucceed() async throws {
        let userInfo: Notifications.Push.UserInfo = ["test": "test"]
        let expectedMessage = "recordNotificationReceived(userInfo:\(userInfo))"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        try await category.recordNotificationReceived(userInfo)
        await waitForExpectations(timeout: 1.0)
    }

    func testRecordNotificationOpened_shouldSucceed() async throws {
        let response = UNNotificationResponse(coder: MockedKeyedArchiver(requiringSecureCoding: false))!
        let expectedMessage = "recordNotificationOpened(response:\(response))"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        try await category.recordNotificationOpened(response)
        await waitForExpectations(timeout: 1.0)
    }

    private class MockedKeyedArchiver: NSKeyedArchiver {
        override func decodeObject(forKey _: String) -> Any { "" }
        override func decodeInt64(forKey key: String) -> Int64 { 0 }
    }
}
