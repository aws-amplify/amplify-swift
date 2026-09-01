//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UserNotifications
import XCTest
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockRemoteNotifications: RemoteNotificationsBehaviour, @unchecked Sendable {
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
