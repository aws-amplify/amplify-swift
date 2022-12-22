//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import Foundation
import StoreKit

extension MockAWSPinpoint {
    public func addGlobalProperty(_ value: AnalyticsPropertyValue, forKey: String) {
        if let value = value as? String {
            addGlobalAttribute(value, forKey: forKey)
        } else if let value = value as? Int {
            addGlobalMetric(Double(value), forKey: forKey)
        } else if let value = value as? Double {
            addGlobalMetric(value, forKey: forKey)
        } else if let value = value as? Bool {
            addGlobalAttribute(String(value), forKey: forKey)
        }
        addGlobalPropertyExpectation?.fulfill()
    }

    public func removeGlobalProperty(_ value: AnalyticsPropertyValue, forKey: String) {
        if value is String || value is Bool {
            removeGlobalAttribute(forKey: forKey)
        } else if value is Int || value is Double {
            removeGlobalMetric(forKey: forKey)
        }
        removeGlobalPropertyExpectation?.fulfill()
    }

    public func addGlobalAttribute(_ theValue: String, forKey theKey: String) {
        addGlobalAttributeCalled += 1

        addGlobalAttributeValue = theValue
        addGlobalAttributeKey = theKey
    }

    public func addGlobalAttribute(_ theValue: String, forKey theKey: String, forEventType theEventType: String) {
        addGlobalAttributeCalled += 1

        addGlobalAttributeValue = theValue
        addGlobalAttributeKey = theKey
        addGlobalAttributeEventType = theEventType
    }

    public func addGlobalMetric(_ theValue: Double, forKey theKey: String) {
        addGlobalMetricCalled += 1

        addGlobalMetricValue = theValue
        addGlobalMetricKey = theKey
    }

    public func addGlobalMetric(_ theValue: Double, forKey theKey: String, forEventType theEventType: String) {
        addGlobalMetricCalled += 1

        addGlobalMetricValue = theValue
        addGlobalMetricKey = theKey
        addGlobalMetricEventType = theEventType
    }

    public func removeGlobalAttribute(forKey theKey: String) {
        removeGlobalAttributeCalled += 1

        removeGlobalAttributeKey = theKey
    }

    public func removeGlobalAttribute(forKey theKey: String, forEventType theEventType: String) {
        removeGlobalAttributeCalled += 1
        removeGlobalAttributeKey = theKey
        removeGlobalAttributeEventType = theEventType
    }

    public func removeGlobalMetric(forKey theKey: String) {
        removeGlobalMetricCalled += 1
        removeGlobalMetricKey = theKey
    }

    public func removeGlobalMetric(forKey theKey: String, forEventType theEventType: String) {
        removeGlobalMetricCalled += 1
        removeGlobalMetricKey = theKey
        removeglobalMetricEventType = theEventType
    }

    public func record(_ theEvent: PinpointEvent) async throws {
        recordCalled += 1
        recordEvent = theEvent

        if case let .failure(error) = recordResult {
            throw error
        }
    }

    public func createEvent(withEventType theEventType: String) -> PinpointEvent {
        createEventCalled += 1
        createEventEventType = theEventType

        return createEventResult ?? createEmptyEvent()
    }

    public func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                             with product: SKProduct) -> PinpointEvent {
        createAppleMonetizationEventCalled += 1
        createAppleMonetizationEventTransaction = transaction
        createAppleMonetizationEventProduct = product

        return createAppleMonetizationEventResult ?? createEmptyEvent()
    }

    public func createVirtualMonetizationEvent(withProductId theProductId: String,
                                               withItemPrice theItemPrice: Double,
                                               withQuantity theQuantity: Int,
                                               withCurrency theCurrency: String) -> PinpointEvent {
        createVirtualMonetizationEventCalled += 1
        createVirtualMonetizationEventProductId = theProductId
        createVirtualMonetizationEventItemPrice = theItemPrice
        createVirtualMonetizationEventQuantity = theQuantity
        createVirtualMonetizationEventCurrency = theCurrency

        return createVirtualMonetizationEventResult ?? createEmptyEvent()
    }

    public func submitEvents() async throws {
        submitEventsCalled += 1
    }

    public func submitEvents() async throws -> [PinpointEvent] {
        submitEventsCalled += 1
        switch submitEventsResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            return []
        }
    }

    private func createEmptyEvent() -> PinpointEvent {
        return PinpointEvent(eventType: "",
                             session: PinpointSession(appId: "", uniqueId: ""))
    }
    
    public func setAutomaticSubmitEventsInterval(_ interval: TimeInterval,
                                                 onSubmit: AnalyticsClientBehaviour.SubmitResult?) {
        
    }
    
    public func startTrackingSessions(backgroundTimeout: TimeInterval) {
        
    }

    func setRemoteGlobalAttributes(_ attributes: [String : String]) async {

    }
}
