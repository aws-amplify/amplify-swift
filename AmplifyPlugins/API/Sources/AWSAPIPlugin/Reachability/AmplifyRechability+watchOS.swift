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

public class AmplifyReachability {
    public var allowsCellularConnection: Bool
   
    // The notification center on which "reachability changed" events are being posted
    public var notificationCenter: NotificationCenter = NotificationCenter.default
    
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
    private var isRunningOnDevice: Bool = {
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
        self.allowsCellularConnection = allowsCellularConnection
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
        networkReachability.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.notificationQueue.async {
                self.notificationCenter.post(name: .reachabilityChanged, object: self)
            }
        }
    }
    
    public func stopNotifier() {
        networkReachability.pathUpdateHandler = nil
    }
}

extension AmplifyReachability {
    public enum Connection: CustomStringConvertible {
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
