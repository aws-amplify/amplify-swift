//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The Notifications parent category
public final class NotificationsCategory {

    /// The Push Notifications category
    public internal(set) var Push = PushNotificationsCategory()

    /// The current available subcategories that have been configured
    var subcategories: [NotificationsSubcategoryBehaviour] {
        let allSubcategories = [
            Push
        ]

        return allSubcategories.filter { $0.isConfigured }
    }
}
