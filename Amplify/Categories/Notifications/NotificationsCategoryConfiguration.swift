//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The configuration for the Notifications category
public struct NotificationsCategoryConfiguration: Codable {
    /// The Push subcategory configuration
    public let push: PushNotificationsCategoryConfiguration?

    public init(push: PushNotificationsCategoryConfiguration? = nil) {
        self.push = push
    }
}
