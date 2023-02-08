//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

typealias ConnectivityUpdates = (ConnectivityPath) -> Void

protocol AnyConnectivityMonitor {
    func start(connectivityUpdatesQueue: DispatchQueue, onConnectivityUpdates: @escaping ConnectivityUpdates)
    func cancel()
}

class ConnectivityMonitor {

    private let connectivityUpdatesQueue = DispatchQueue(
        label: "com.amazonaws.ConnectivityMonitor.connectivityUpdatesQueue",
        qos: .background
    )
    private var monitor: AnyConnectivityMonitor?

    init(monitor: AnyConnectivityMonitor? = nil) {
        self.monitor = monitor
    }

    func start(onUpdates: @escaping ConnectivityUpdates) {
        if let monitor = monitor {
            monitor.start(
                connectivityUpdatesQueue: connectivityUpdatesQueue,
                onConnectivityUpdates: onUpdates
            )
        } else if #available(iOS 12.0, *) {
            let monitor = NetworkMonitor()
            self.monitor = monitor
            monitor.start(
                connectivityUpdatesQueue: connectivityUpdatesQueue,
                onConnectivityUpdates: onUpdates
            )
        }
    }

    func cancel() {
        guard let monitor = monitor else {
            return
        }
        monitor.cancel()
    }

    deinit {
        cancel()
    }
}

@available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 6.0, *)
class NetworkMonitor: AnyConnectivityMonitor {
    private var monitor: NWPathMonitor?
    private var onConnectivityUpdates: ConnectivityUpdates?
    private var connectivityUpdatesQueue: DispatchQueue?
    private let queue = DispatchQueue(label: "com.amazonaws.NetworkMonitor.queue", qos: .background)

    func start(connectivityUpdatesQueue: DispatchQueue, onConnectivityUpdates: @escaping ConnectivityUpdates) {
        self.connectivityUpdatesQueue = connectivityUpdatesQueue
        self.onConnectivityUpdates = onConnectivityUpdates
        // A new instance is required each time a monitor is started
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
        guard let onConnectivityUpdates = onConnectivityUpdates,
              let connectivityUpdatesQueue = connectivityUpdatesQueue else {
            return
        }
        let connectivityPath = ConnectivityPath(path: path)
        connectivityUpdatesQueue.async {
            onConnectivityUpdates(connectivityPath)
        }
    }
}
