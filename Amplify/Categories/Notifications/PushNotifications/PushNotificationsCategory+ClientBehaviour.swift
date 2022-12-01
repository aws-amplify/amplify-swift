//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UserNotifications

extension PushNotificationsCategory: PushNotificationsCategoryBehaviour {
    public func identifyUser(userId: String) async throws {
        try await plugin.identifyUser(userId: userId)
    }
    
    public func registerDevice(apnsToken: Data) async throws {
        try await plugin.registerDevice(apnsToken: apnsToken)
    }
    
    public func recordNotificationReceived(_ userInfo: Notifications.Push.UserInfo) async {
        await plugin.recordNotificationReceived(userInfo)
    }
    
    public func recordNotificationOpened(_ response: UNNotificationResponse) async {
        await plugin.recordNotificationOpened(response)
    }
}
