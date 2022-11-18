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
    
    func registerDevice(token: Data) {
        notify("registerDevice(token:\(token))")
    }
    
    func registerDidReceive(_ userInfo: NotificationUserInfo) {
        notify("registerDidReceive(userInfo:\(userInfo))")
    }
    
    func registerDidReceive(_ response: UNNotificationResponse) {
        notify("registerDidReceive(response:\(response))")
    }
}

class MockSecondPushNotificationsCategoryPlugin: MockPushNotificationsCategoryPlugin {
    override var key: String {
        "MockSecondPushNotificationsCategoryPlugin"
    }
}
