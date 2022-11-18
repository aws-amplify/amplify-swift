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
        // TODO: Replace with proper classes once they are implemented
        public typealias AppDelegate = NSObject
        public typealias ServiceExtension = UNNotificationServiceExtension
        public typealias NotificationPayload = Decodable
    }
}
