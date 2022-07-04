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

    var addGlobalAttributeCalls = [(String, String)]()
    func addGlobalAttribute(_ attribute: String, forKey key: String) {
        addGlobalAttributeCalls.append((key, attribute))
    }
    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String) {}
    
    func addGlobalMetric(_ metric: Double, forKey key: String) {}
    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String) {}
    
    var removeGlobalAttributeCalls = [(String, String?)]()
    func removeGlobalAttribute(forKey key: String) {
        removeGlobalAttributeCalls.append((key, nil))
    }
    
    func removeGlobalAttribute(forKey key: String, forEventType eventType: String) {
        removeGlobalAttributeCalls.append((key, eventType))
    }
    
    var removeGlobalMetricCalls = [(String, String?)]()
    func removeGlobalMetric(forKey key: String) {
        removeGlobalMetricCalls.append((key, nil))
    }
    
    func removeGlobalMetric(forKey key: String, forEventType eventType: String) {
        removeGlobalMetricCalls.append((key, eventType))
    }

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
    
    func setGlobalEventSourceAttributes(_ attributes: [String : Any]) {
        
    }
    
    func removeAllGlobalEventSourceAttributes() {
        
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
        removeGlobalAttributeCalls = []
        addGlobalAttributeCalls = []
    }
}
