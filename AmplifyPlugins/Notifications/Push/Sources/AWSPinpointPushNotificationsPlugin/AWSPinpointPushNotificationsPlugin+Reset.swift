//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSPinpointPushNotificationsPlugin {
    public func reset() {
        if pinpoint != nil {
            pinpoint = nil
        }

        options = []
    }
}
