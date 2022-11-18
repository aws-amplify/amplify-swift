//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UserNotifications
#if canImport(UIKit)
public typealias NotificationUserInfo = [AnyHashable: Any]
#else
public typealias NotificationUserInfo = [String: Any]
#endif

/// Defines the behaviour of the Push Notifications category that clients will use
public protocol PushNotificationsCategoryBehaviour: NotificationsSubcategoryBehaviour {
    // TODO: These APIs can change. Document them once finalized.

    func identifyUser(userId: String)
    
    func registerDevice(token: Data)
    
    func registerDidReceive(_ userInfo: NotificationUserInfo)
    
    func registerDidReceive(_ response: UNNotificationResponse)
}
