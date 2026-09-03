//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(watchOS)
import Foundation

@available(*, unavailable, renamed: "Notification.Name.reachabilityChanged")
public let reachabilityChangedNotification = NSNotification.Name("ReachabilityChangedNotification")

public extension Notification.Name {
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

import Foundation
import Network

/// - Note: `@unchecked Sendable` because `startNotifier()` hands `self` to `NWPathMonitor`'s
///   `pathUpdateHandler`, which is a `@Sendable` closure invoked on the monitor's own queue. The
///   settable properties below are therefore genuinely shared, so `lock` guards them. Not `final`:
///   this is public API, and `@unchecked Sendable` does not require it.
public class AmplifyReachability: @unchecked Sendable {
    private let lock = NSLock()

    private var _allowsCellularConnection: Bool

    public var allowsCellularConnection: Bool {
        get { lock.withLock { _allowsCellularConnection } }
        set { lock.withLock { _allowsCellularConnection = newValue } }
    }

    private var _notificationCenter: NotificationCenter = .default

    // The notification center on which "reachability changed" events are being posted
    public var notificationCenter: NotificationCenter {
        get { lock.withLock { _notificationCenter } }
        set { lock.withLock { _notificationCenter = newValue } }
    }

    public var connection: AmplifyReachability.Connection {
        guard networkReachability.currentPath.status != .unsatisfied else {
            return .unavailable
        }

        // If we're reachable but not running on a device, we must be in Wi-Fi
        if !isRunningOnDevice {
            return .wifi
        }

        if networkReachability.currentPath.usesInterfaceType(.wifi) {
            return .wifi
        }

        if networkReachability.currentPath.usesInterfaceType(.cellular) {
            return allowsCellularConnection ? .cellular : .unavailable
        }

        return .unavailable
    }

    private let networkReachability: NWPathMonitor
    private let notificationQueue: DispatchQueue
    private let isRunningOnDevice: Bool = {
#if targetEnvironment(simulator)
        return false
#else
        return true
#endif
    }()

    public init(
        networkReachability: NWPathMonitor = NWPathMonitor(),
        allowsCellularConnection: Bool = true,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue = .main
    ) {
        self._allowsCellularConnection = allowsCellularConnection
        self.networkReachability = networkReachability
        networkReachability.start(
            queue: DispatchQueue(
                label: "com.amazonaws.Amplify.AWSAPIPlugin.AmplifyReachability",
                qos: queueQoS,
                target: targetQueue
            )
        )
        self.notificationQueue = notificationQueue
    }

    deinit {
        stopNotifier()
    }

    // MARK: - *** Notifier methods ***
    public func startNotifier() throws {
        guard networkReachability.pathUpdateHandler == nil else { return }
        networkReachability.pathUpdateHandler = { [weak self] _ in
            guard let self else { return }
            notificationQueue.async {
                self.notificationCenter.post(name: .reachabilityChanged, object: self)
            }
        }
    }

    public func stopNotifier() {
        networkReachability.pathUpdateHandler = nil
    }
}

public extension AmplifyReachability {
    enum Connection: CustomStringConvertible {
        @available(*, deprecated, renamed: "unavailable")
        case none
        case unavailable, wifi, cellular
        public var description: String {
            switch self {
            case .cellular: return "Cellular"
            case .wifi: return "WiFi"
            case .unavailable: return "No Connection"
            case .none: return "unavailable"
            }
        }
    }
}
#endif
