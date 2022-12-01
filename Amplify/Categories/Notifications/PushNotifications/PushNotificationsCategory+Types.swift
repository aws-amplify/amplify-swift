//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UserNotifications

extension Notifications {
    public enum Push {
    #if canImport(UIKit)
        public typealias UserInfo = [AnyHashable: Any]
    #elseif canImport(AppKit)
        public typealias UserInfo = [String: Any]
    #endif
        // TODO: Replace with proper classes once they are implemented
        public typealias AppDelegate = NSObject
        public typealias ServiceExtension = UNNotificationServiceExtension
        public typealias NotificationPayload = Decodable
    }
}
