//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
extension AWSPinpointAnalyticsPlugin {

    /// Resets the state of the plugin
    public func reset(onComplete: @escaping (() -> Void)) {

        if pinpoint != nil {
            pinpoint = nil
        }

        if authService != nil {
            authService = nil
        }

        if flushEventsTracker != nil {
            flushEventsTracker = nil
        }

        if appSessionTracker != nil {
            appSessionTracker = nil
        }

        if globalProperties != nil {
            globalProperties = nil
        }

        if isEnabled != nil {
            isEnabled = nil
        }

        onComplete()
    }
}
