//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Combine

class NetworkReachabilityNotifier {
    private var reachability: NetworkReachabilityProviding?
    private var allowsCellularAccess = true

    // This is a CurrentValueSubject.  Please do not change this unless you talk to wooj2@ or palpatim@ before changing this.
    let reachabilityPublisher = CurrentValueSubject<ReachabilityUpdate, Never>(ReachabilityUpdate(isOnline: false))
    var publisher: AnyPublisher<ReachabilityUpdate, Never> {
        return reachabilityPublisher.eraseToAnyPublisher()
    }

    public init(host: String,
                allowsCellularAccess: Bool,
                reachabilityFactory: NetworkReachabilityProvidingFactory.Type) throws {
        self.reachability = reachabilityFactory.make(for: host)
        self.allowsCellularAccess = allowsCellularAccess

        // Add listener for Reachability and start its notifier
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(respondToReachabilityChange),
                                               name: .reachabilityChanged,
                                               object: nil)
        do {
            try reachability?.startNotifier()
        } catch {
            throw error
        }
    }

    deinit {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self)
        reachabilityPublisher.send(completion: Subscribers.Completion<Never>.finished)
    }

    // MARK: - Notifications
    @objc private func respondToReachabilityChange() {
        guard let reachability = reachability else {
            return
        }

        let isReachable: Bool
        switch reachability.connection {
        case .wifi:
            isReachable = true
        case .cellular:
            isReachable = allowsCellularAccess
        case .none, .unavailable:
            isReachable = false
        }

        let reachabilityMessageUpdate = ReachabilityUpdate(isOnline: isReachable)
        reachabilityPublisher.send(reachabilityMessageUpdate)
    }

}

// MARK: - Reachability
extension AmplifyReachability: NetworkReachabilityProvidingFactory {
    public static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return try? AmplifyReachability(hostname: hostname)
    }
}

extension AmplifyReachability: NetworkReachabilityProviding { }
