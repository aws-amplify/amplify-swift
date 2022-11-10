//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol GeoNetworkMonitorBehavior {
    
    func start()
    
    func cancel()
    
    func networkConnected() -> Bool
    
}
