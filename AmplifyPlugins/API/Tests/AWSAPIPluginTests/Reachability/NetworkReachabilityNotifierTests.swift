//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
@testable import Amplify
@testable import AWSAPIPlugin

class NetworkReachabilityNotifierTests: XCTestCase {
    var notification: Notification!
    var notifier: NetworkReachabilityNotifier!

    override func setUp() {
        do {
            notifier = try NetworkReachabilityNotifier(
                host: "localhost",
                allowsCellularAccess: true,
                reachabilityFactory: MockNetworkReachabilityProvidingFactory.self
            )
        } catch {
            XCTFail("failed to init NetworkReachabilityNotifier")
        }
        MockReachability.iConnection = .wifi
    }

    func testWifiConnectivity() async {
        MockReachability.iConnection = .wifi
        let expect = expectation(description: ".sink receives values")
        var values = [Bool]()
        let cancellable = notifier.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting any error")
        }, receiveValue: { (value: ReachabilityUpdate) -> Void in
            values.append(value.isOnline)
            if values.count == 2 {
                XCTAssertFalse(values[0])
                XCTAssertTrue(values[1])
                expect.fulfill()
            }
        })
        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        await fulfillment(of: [expect], timeout: 1)
        cancellable.cancel()
    }

    func testCellularConnectivity() async {
        MockReachability.iConnection = .wifi
        let expect = expectation(description: ".sink receives values")
        var values = [Bool]()
        let cancellable = notifier.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting any error")
        }, receiveValue: { (value: ReachabilityUpdate) -> Void in
            values.append(value.isOnline)
            if values.count == 2 {
                XCTAssertFalse(values[0])
                XCTAssertTrue(values[1])
                expect.fulfill()
            }
        })

        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        await fulfillment(of: [expect], timeout: 1)
        cancellable.cancel()
    }

    func testNoConnectivity() async {
        MockReachability.iConnection = .unavailable
        let expect = expectation(description: ".sink receives values")
        var values = [Bool]()
        let cancellable = notifier.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting any error")
        }, receiveValue: { (value: ReachabilityUpdate) -> Void in
            values.append(value.isOnline)
            if values.count == 2 {
                XCTAssertFalse(values[0])
                XCTAssertFalse(values[1])
                expect.fulfill()
            }
        })

        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        await fulfillment(of: [expect], timeout: 1)
        cancellable.cancel()
    }

    func testWifiConnectivity_publisherGoesOutOfScope() async {
        MockReachability.iConnection = .wifi
        let defaultValueExpect = expectation(description: ".sink receives default value")
        let completeExpect = expectation(description: ".sink receives completion")
        let cancellable = notifier.publisher.sink(receiveCompletion: { _ in
            completeExpect.fulfill()
        }, receiveValue: { (value: ReachabilityUpdate) -> Void in
            XCTAssertFalse(value.isOnline)
            defaultValueExpect.fulfill()
        })

        await fulfillment(of: [defaultValueExpect], timeout: 1.0)
        notifier = nil
        notification = Notification.init(name: .reachabilityChanged)
        NotificationCenter.default.post(notification)

        await fulfillment(of: [completeExpect], timeout: 1.0)
        cancellable.cancel()
    }
}
