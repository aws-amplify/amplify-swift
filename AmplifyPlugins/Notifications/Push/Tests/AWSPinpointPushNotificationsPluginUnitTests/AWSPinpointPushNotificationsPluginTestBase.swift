//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UserNotifications
import XCTest
@testable import Amplify
@testable import AWSPinpointPushNotificationsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSPinpointPushNotificationsPluginTestBase: XCTestCase, @unchecked Sendable {
    var plugin: AWSPinpointPushNotificationsPlugin!
    var mockPinpoint: MockAWSPinpoint!
    var mockRemoteNotifications: MockRemoteNotifications!

    let testAppId = "56e6f06fd4f244c6b202bc1234567890"
    let testRegion = "us-east-1"
    let authorizationOptions: UNAuthorizationOptions = [.badge]

    override func setUp() async throws {
        plugin = AWSPinpointPushNotificationsPlugin(options: authorizationOptions)
        mockPinpoint = MockAWSPinpoint()
        mockRemoteNotifications = MockRemoteNotifications()
    }

    override func tearDown() async throws {
        let resettable = plugin as Resettable
        await resettable.reset()
    }
}
