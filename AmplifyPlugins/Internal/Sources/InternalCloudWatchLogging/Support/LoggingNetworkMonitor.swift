//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

/// Provides a network monitor for logging.
package protocol LoggingNetworkMonitor: AnyObject {
    var isOnline: Bool { get }
    func startMonitoring(using queue: DispatchQueue)
    func stopMonitoring()
}

extension NWPathMonitor: LoggingNetworkMonitor {
    package var isOnline: Bool {
        currentPath.status == .satisfied
    }

    package func startMonitoring(using queue: DispatchQueue) {
        start(queue: queue)
    }

    package func stopMonitoring() {
        cancel()
    }
}
