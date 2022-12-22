//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyUtilsNotifications
import Foundation

extension AWSPinpointPushNotificationsPlugin {
    /// Service Extension that can handle AWS Pinpoint rich notifications.
    public typealias ServiceExtension = AUNotificationService

    /// A protocol that can be used to customize the expeded payload that the ServiceExtension can handle.
    public typealias NotificationPayload = AUNotificationPayload
}
