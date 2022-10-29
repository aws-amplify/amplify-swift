//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Network

@available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.0, *)
class GeoNetworkMonitor {
    
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.amazonaws.GeoNetworkMonitor.queue", qos: .background)
    private var pathStatus: NWPath.Status = .satisfied
    
    func start() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = didUpdate(path:)
        monitor.start(queue: queue)
        self.monitor = monitor
    }
    
    func cancel() {
        guard let monitor = monitor else { return }
        defer {
            self.monitor = nil
        }
        monitor.cancel()
    }
    
    func didUpdate(path: NWPath) {
        self.pathStatus = path.status
    }
    
    func networkConnected() -> Bool {
        return self.pathStatus == .satisfied
    }
}
