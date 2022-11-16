//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint

extension AWSPinpointAnalyticsPlugin {
    /// Resets the state of the plugin
    public func reset() {
        if pinpoint != nil {
            pinpoint = nil
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
