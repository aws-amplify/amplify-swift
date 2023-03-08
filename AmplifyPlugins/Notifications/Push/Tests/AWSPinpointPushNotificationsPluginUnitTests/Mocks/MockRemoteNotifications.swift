//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import UserNotifications
import XCTest

class MockRemoteNotifications: RemoteNotificationsBehaviour {
    var isRegisteredForRemoteNotifications: Bool = true

    var mockedRequestAuthorizationResult: Bool = true
    var requestAuthorizationError: Error?
    func requestAuthorization(_ options: UNAuthorizationOptions) async throws -> Bool {
        if let error = requestAuthorizationError {
            throw error
        }
        return mockedRequestAuthorizationResult
    }

    var registerForRemoteNotificationsExpectation: XCTestExpectation?
    func registerForRemoteNotifications() async {
        registerForRemoteNotificationsExpectation?.fulfill()
    }
}
