//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import UserNotifications

class MockPushNotificationsCategoryPlugin: MessageReporter, PushNotificationsCategoryPlugin {
    var key: String {
        "MockPushNotificationsCategoryPlugin"
    }
    
    func configure(using configuration: Any?) throws {
        notify()
    }
    
    func reset() async {
        notify()
    }
    
    func identifyUser(userId: String) {
        notify("identifyUser(userId:\(userId))")
    }
    
    func registerDevice(apnsToken: Data) {
        notify("registerDevice(token:\(apnsToken))")
    }
    
    func recordNotificationReceived(_ userInfo: Notifications.Push.UserInfo) {
        notify("recordNotificationReceived(userInfo:\(userInfo))")
    }
    
    func recordNotificationOpened(_ response: UNNotificationResponse) {
        notify("recordNotificationOpened(response:\(response))")
    }
}

class MockSecondPushNotificationsCategoryPlugin: MockPushNotificationsCategoryPlugin {
    override var key: String {
        "MockSecondPushNotificationsCategoryPlugin"
    }
}
