//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import UserNotifications

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockPushNotificationsCategoryPlugin: MessageReporter, PushNotificationsCategoryPlugin, @unchecked Sendable {
    var key: String {
        "MockPushNotificationsCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() async {
        notify()
    }

    func identifyUser(userId: String, userProfile: AmplifyUserProfile?) {
        notify("identifyUser(userId:\(userId))")
    }

    func registerDevice(apnsToken: Data) {
        notify("registerDevice(token:\(apnsToken))")
    }

    func recordNotificationReceived(_ userInfo: Notifications.Push.UserInfo) {
        notify("recordNotificationReceived(userInfo:\(userInfo))")
    }

#if !os(tvOS)
    func recordNotificationOpened(_ response: UNNotificationResponse) {
        notify("recordNotificationOpened(response:\(response))")
    }
#endif
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondPushNotificationsCategoryPlugin: MockPushNotificationsCategoryPlugin, @unchecked Sendable {
    override var key: String {
        "MockSecondPushNotificationsCategoryPlugin"
    }
}
