//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@testable import AWSLocationGeoPlugin

class MockGeoNetworkMonitor: GeoNetworkMonitorBehavior {
    
    var isNetworkConnected: Bool = true
    
    func start() {
        // do nothing
    }
    
    func cancel() {
        // do nothing
    }
    
    func networkConnected() -> Bool {
        return isNetworkConnected
    }
    
    
}
