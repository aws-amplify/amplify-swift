//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
extension AWSPinpointAnalyticsPlugin {
    /// Resets the state of the plugin
    public func reset() {
        if pinpoint != nil {
            pinpoint = nil
        }

        if authService != nil {
            authService = nil
        }

        if autoFlushEventsTimer != nil {
            autoFlushEventsTimer?.setEventHandler {}
            autoFlushEventsTimer?.cancel()
            autoFlushEventsTimer = nil
        }

        if globalProperties != nil {
            globalProperties = nil
        }

        if isEnabled != nil {
            isEnabled = nil
        }
        
        if networkMonitor != nil {
            networkMonitor.stopMonitoring()
            networkMonitor = nil
        }
    }
}
