//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import UserNotifications

/// The AWSPinpointPushNotificationsPlugin implements the Push Notifications support for Pinpoint
public final class AWSPinpointPushNotificationsPlugin: PushNotificationsCategoryPlugin {
    /// An instance of the AWS Pinpoint service
    var pinpoint: AWSPinpointBehavior!

    /// The `UNAuthorizationOptions` permissions  that are going to be requested.
    var options: UNAuthorizationOptions

    /// The unique key of the plugin within the Push Notifications category
    public var key: PluginKey {
        "awsPinpointPushNotificationsPlugin"
    }

    /// Creates an instance of the AWSPinpointPushNotificationsPlugin and requests Push Notifications authorization from the user.
    ///
    /// - Parameter options: The `UNAuthorizationOptions` permissions to request. Defaults to `badge`, `alert` and `sound`.
    public init(options: UNAuthorizationOptions = [.badge, .alert, .sound]) {
        self.options = options
    }
}

extension AWSPinpointPushNotificationsPlugin: AmplifyVersionable { }
