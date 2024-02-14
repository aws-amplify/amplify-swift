//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

protocol NetworkMonitor: AnyObject {
    var isOnline: Bool { get }
    func startMonitoring(using queue: DispatchQueue)
    func stopMonitoring()
}

extension NWPathMonitor: NetworkMonitor {
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
