//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

/// Provides a network monitor for logging
protocol LoggingNetworkMonitor: AnyObject {
    var isOnline: Bool { get }
    func startMonitoring(using queue: DispatchQueue)
    func stopMonitoring()
}

extension NWPathMonitor: LoggingNetworkMonitor {
    var isOnline: Bool {
        currentPath.status == .satisfied
    }
    
    func startMonitoring(using queue: DispatchQueue) {
        start(queue: queue)
    }
    
    func stopMonitoring() {
        cancel()
    }
}
