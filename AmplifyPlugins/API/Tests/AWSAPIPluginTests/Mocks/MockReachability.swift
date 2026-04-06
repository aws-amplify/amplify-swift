//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSAPIPlugin
import Foundation

class MockNetworkReachabilityProvidingFactory: NetworkReachabilityProvidingFactory {
#if os(watchOS)
    static func make() -> NetworkReachabilityProviding? {
        return MockReachability()
    }
#else
    static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return MockReachability()
    }
#endif
}

class MockReachability: NetworkReachabilityProviding {
    var allowsCellularConnection = true
    nonisolated(unsafe) static var iConnection = AmplifyReachability.Connection.wifi
    var connection: AmplifyReachability.Connection {
        get {
            return MockReachability.iConnection
        }
        set(conn) {
            MockReachability.iConnection = conn
        }
    }

    var notificationCenter: NotificationCenter = .default

    func startNotifier() throws {
    }

    func stopNotifier() {
    }
}
