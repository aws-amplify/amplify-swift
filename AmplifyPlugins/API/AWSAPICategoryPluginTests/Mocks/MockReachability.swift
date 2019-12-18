//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Reachability
import AWSAPICategoryPlugin

class MockNetworkReachabilityProvidingFactory: NetworkReachabilityProvidingFactory {
    public static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return MockReachability()
    }
}

class MockReachability: NetworkReachabilityProviding {
    var allowsCellularConnection = true
    static var iConnection = Reachability.Connection.wifi
    var connection: Reachability.Connection {
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
