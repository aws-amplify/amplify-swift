//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UserNotifications

extension PushNotificationsCategory: PushNotificationsCategoryBehaviour {
    public func identifyUser(userId: String) {
        plugin.identifyUser(userId: userId)
    }
    
    public func registerDevice(token: Data) {
        plugin.registerDevice(token: token)
    }
    
    public func registerDidReceive(_ userInfo: NotificationUserInfo) {
        plugin.registerDidReceive(userInfo)
    }
    
    public func registerDidReceive(_ response: UNNotificationResponse) {
        plugin.registerDidReceive(response)
    }
}
