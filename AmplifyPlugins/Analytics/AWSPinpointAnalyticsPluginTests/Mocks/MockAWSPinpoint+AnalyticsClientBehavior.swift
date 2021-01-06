//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import Foundation

extension MockAWSPinpoint: AWSPinpointAnalyticsClientBehavior {
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

    public func addGlobalMetric(_ theValue: NSNumber, forKey theKey: String) {
        addGlobalMetricCalled += 1

        addGlobalMetricValue = theValue
        addGlobalMetricKey = theKey
    }

    public func addGlobalMetric(_ theValue: NSNumber, forKey theKey: String, forEventType theEventType: String) {
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

    public func record(_ theEvent: AWSPinpointEvent) -> AWSTask<AnyObject> {
        recordCalled += 1
        recordEvent = theEvent

        return recordResult ?? AWSTask<AnyObject>.init(result: "" as AnyObject)
    }

    public func createEvent(withEventType theEventType: String) -> AWSPinpointEvent {
        createEventCalled += 1
        createEventEventType = theEventType

        return createEventResult ?? AWSPinpointEvent()
    }

    public func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                             with product: SKProduct) -> AWSPinpointEvent {
        createAppleMonetizationEventCalled += 1
        createAppleMonetizationEventTransaction = transaction
        createAppleMonetizationEventProduct = product

        return createAppleMonetizationEventResult ?? AWSPinpointEvent()
    }

    public func createVirtualMonetizationEvent(withProductId theProductId: String,
                                               withItemPrice theItemPrice: Double,
                                               withQuantity theQuantity: Int,
                                               withCurrency theCurrency: String) -> AWSPinpointEvent {
        createVirtualMonetizationEventCalled += 1
        createVirtualMonetizationEventProductId = theProductId
        createVirtualMonetizationEventItemPrice = theItemPrice
        createVirtualMonetizationEventQuantity = theQuantity
        createVirtualMonetizationEventCurrency = theCurrency

        return createVirtualMonetizationEventResult ?? AWSPinpointEvent()
    }

    public func submitEvents() -> AWSTask<AnyObject> {
        submitEventsCalled += 1

        return submitEventsResult ?? AWSTask<AnyObject>.init(result: "" as AnyObject)
    }

    public func submitEvents(completionBlock: @escaping AWSPinpointCompletionBlock) -> AWSTask<AnyObject> {
        submitEventsCalled += 1

        if let result = submitEventsResult {
            _ = completionBlock(result)
        }

        return submitEventsResult ?? AWSTask<AnyObject>.init(result: "" as AnyObject)
    }
}
