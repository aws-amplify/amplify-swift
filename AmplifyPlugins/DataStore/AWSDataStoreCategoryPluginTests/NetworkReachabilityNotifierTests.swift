//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Reachability
import Combine
@testable import AWSDataStoreCategoryPlugin

class NetworkReachabilityNotifierTests: XCTestCase {
    var networkReach: NetworkReachabilityNotifier!
    var notification: Notification!

    override func setUp() {
        networkReach = NetworkReachabilityNotifier(host: "localhost",
                                                   allowsCellularAccess: true,
                                                   reachabilityFactory: MockNetworkReachabilityProvidingFactory.self)
        MockReachability.iConnection = .wifi
    }

    func testWifiConnectivity() {
        MockReachability.iConnection = .wifi
        let expect = expectation(description: ".sink receives value")
        let cancellable = networkReach.publisher()
            .sink { value in
                XCTAssert(value.isOnline)
                expect.fulfill()
        }

        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        waitForExpectations(timeout: 1)
    }

    func testCellularConnectivity() {
        MockReachability.iConnection = .cellular
        let expect = expectation(description: ".sink receives value")
        let cancellable = networkReach.publisher()
            .sink { value in
                XCTAssert(value.isOnline)
                expect.fulfill()
        }

        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        waitForExpectations(timeout: 1)
    }

    func testNoConnectivity() {
        MockReachability.iConnection = .unavailable
        let expect = expectation(description: ".sink receives value")
        let cancellable = networkReach.publisher()
            .sink { value in
                XCTAssertFalse(value.isOnline)
                expect.fulfill()
        }

        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        waitForExpectations(timeout: 1)
    }

    func testWifiConnectivity_publisherGoesOutOfScope() {
        MockReachability.iConnection = .wifi
        let expect = expectation(description: ".sink receives value")
        let cancellable = networkReach.publisher()
            .print()
            .sink(receiveCompletion: { _ in
                expect.fulfill()
            }, receiveValue: { _ in
                XCTAssertFalse(true)
            })

        networkReach = nil
        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        waitForExpectations(timeout: 1)
    }
}

class MockNetworkReachabilityProvidingFactory: NetworkReachabilityProvidingFactory {
    public static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return try? MockReachability()
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

    func setConnection(connection: Reachability.Connection) {
        self.connection = connection
    }

    func startNotifier() throws {
    }

    func stopNotifier() {
    }
}
