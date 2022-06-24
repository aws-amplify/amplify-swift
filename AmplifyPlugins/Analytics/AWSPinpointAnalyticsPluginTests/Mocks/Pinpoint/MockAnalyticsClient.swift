//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import StoreKit
import XCTest

actor MockAnalyticsClient: AnalyticsClientBehaviour {
    let pinpointClient: PinpointClientProtocol = MockPinpointClient()

    func addGlobalAttribute(_ attribute: String, forKey key: String) {}
    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String) {}
    func addGlobalMetric(_ metric: Double, forKey key: String) {}
    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String) {}
    func removeGlobalAttribute(forKey key: String) {}
    func removeGlobalAttribute(forKey key: String, forEventType eventType: String) {}
    func removeGlobalMetric(forKey key: String) {}
    func removeGlobalMetric(forKey key: String, forEventType eventType: String) {}

    nonisolated func createAppleMonetizationEvent(with transaction: SKPaymentTransaction, with product: SKProduct) -> PinpointEvent {
        return PinpointEvent(eventType: "Apple", session: PinpointSession(appId: "", uniqueId: ""))
    }

    nonisolated func createVirtualMonetizationEvent(withProductId productId: String, withItemPrice itemPrice: Double, withQuantity quantity: Int, withCurrency currency: String) -> PinpointEvent {
        return PinpointEvent(eventType: "Virtual", session: PinpointSession(appId: "", uniqueId: ""))
    }

    var createEventCount = 0
    private func increaseCreateEventCount() {
        createEventCount += 1
    }

    nonisolated func createEvent(withEventType eventType: String) -> PinpointEvent {
        Task {
            await increaseCreateEventCount()
        }
        return PinpointEvent(eventType: eventType, session: PinpointSession(appId: "", uniqueId: ""))
    }

    private var recordExpectation: XCTestExpectation?
    func setRecordExpectation(_ expectation: XCTestExpectation, count: Int = 1) {
        recordExpectation = expectation
        recordExpectation?.expectedFulfillmentCount = count
    }

    var recordCount = 0
    var lastRecordedEvent: PinpointEvent?
    var recordedEvents: [PinpointEvent] = []
    func record(_ event: PinpointEvent) async throws {
        recordCount += 1
        lastRecordedEvent = event
        recordedEvents.append(event)
        recordExpectation?.fulfill()
    }

    private var submitEventsExpectation: XCTestExpectation?
    func setSubmitEventsExpectation(_ expectation: XCTestExpectation, count: Int = 1) {
        submitEventsExpectation = expectation
        submitEventsExpectation?.expectedFulfillmentCount = count
    }

    var submitEventsCount = 0
    func submitEvents() async throws -> [PinpointEvent] {
        submitEventsCount += 1
        submitEventsExpectation?.fulfill()
        return []
    }

    func resetCounters() {
        recordCount = 0
        submitEventsCount = 0
        createEventCount = 0
        recordedEvents = []
        lastRecordedEvent = nil
    }
}
