//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyUtilsNotifications
import Foundation

public extension AWSPinpointPushNotificationsPlugin {

#if !os(tvOS)
    /// Service Extension that can handle AWS Pinpoint rich notifications.
    typealias ServiceExtension = AUNotificationService
#endif

    /// A protocol that can be used to customize the expeded payload that the ServiceExtension can handle.
    typealias NotificationPayload = AUNotificationPayload
}
