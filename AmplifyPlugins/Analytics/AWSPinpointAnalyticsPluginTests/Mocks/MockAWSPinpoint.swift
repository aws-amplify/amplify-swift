//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
import XCTest

@testable import AWSPinpointAnalyticsPlugin

public class MockAWSPinpoint: AWSPinpointBehavior {
    let applicationId = "applicationId"
    let endpointId = "endpointId"

    // MARK: Method call counts for AWSPinpointTargetingClient

    var currentEndpointProfileCalled = 0
    var updateEndpointProfileCalled = 0
    var addAttributeCalled = 0
    var removeAttributeCalled = 0
    var addMetricCalled = 0
    var removeMetricCalled = 0
    var escapeHatchCalled = 0

    // MARK: Method arguments for AWSPinpointTargetingClient

    var updateEndpointProfileValue: AWSPinpointEndpointProfile?
    var addAttributeValue: [Any]?
    var addAttributeKey: String?
    var removeAttributeKey: String?
    var addMetricValue: NSNumber?
    var addMetricKey: String?
    var removeMetricKey: String?

    // MARK: Method call counts for AWSPinpointAnalyticsClient

    var addGlobalAttributeCalled = 0
    var addGlobalMetricCalled = 0
    var removeGlobalAttributeCalled = 0
    var removeGlobalMetricCalled = 0
    var recordCalled = 0
    var createEventCalled = 0
    var createAppleMonetizationEventCalled = 0
    var createVirtualMonetizationEventCalled = 0
    var submitEventsCalled = 0

    // MARK: Method arguments for AWSPinpointAnalyticsClient

    var addGlobalAttributeValue: String?
    var addGlobalAttributeKey: String?
    var addGlobalAttributeEventType: String?
    var addGlobalMetricValue: NSNumber?
    var addGlobalMetricKey: String?
    var addGlobalMetricEventType: String?
    var removeGlobalAttributeKey: String?
    var removeGlobalAttributeEventType: String?
    var removeGlobalMetricKey: String?
    var removeglobalMetricEventType: String?
    var recordEvent: AWSPinpointEvent?
    var createEventEventType: String?
    var createAppleMonetizationEventTransaction: SKPaymentTransaction?
    var createAppleMonetizationEventProduct: SKProduct?
    var createVirtualMonetizationEventProductId: String?
    var createVirtualMonetizationEventItemPrice: Double?
    var createVirtualMonetizationEventQuantity: Int?
    var createVirtualMonetizationEventCurrency: String?

    // MARK: Mock behavior for AWSPinpointTargetingClient

    var updateEndpointProfileResult: AWSTask<AnyObject>?

    // MARK: Mock behavior for AWSPinpointAnalyticsClient

    var recordResult: AWSTask<AnyObject>?
    var createEventResult: AWSPinpointEvent?
    var createAppleMonetizationEventResult: AWSPinpointEvent?
    var createVirtualMonetizationEventResult: AWSPinpointEvent?
    var submitEventsResult: AWSTask<AnyObject>?

    public init() {}

    public func getEscapeHatch() -> AWSPinpoint {
        escapeHatchCalled += 1
        return AWSPinpoint()
    }
}

extension MockAWSPinpoint {
    public func verifyCurrentEndpointProfile() {
        XCTAssertEqual(currentEndpointProfileCalled, 1)
    }

    public func verifyUpdateEndpointProfile() {
        XCTAssertEqual(updateEndpointProfileCalled, 1)
    }

    public func verifyUpdate(_ endpointProfile: AWSPinpointEndpointProfile) {
        XCTAssertEqual(updateEndpointProfileCalled, 1)
        XCTAssertNotNil(updateEndpointProfileValue)
        guard let actualEndpointProfile = updateEndpointProfileValue else {
            XCTFail("actual EndpointProfile is nil")
            return
        }

        if endpointProfile.location != nil {
            guard let actualLocation = actualEndpointProfile.location else {
                XCTFail("actual Location is nil")
                return
            }
            let expectedLocation = endpointProfile.location!
            XCTAssertEqual(actualLocation.latitude, expectedLocation.latitude)
            XCTAssertEqual(actualLocation.longitude, expectedLocation.longitude)
            XCTAssertEqual(actualLocation.postalCode, expectedLocation.postalCode)
            XCTAssertEqual(actualLocation.city, expectedLocation.city)
            XCTAssertEqual(actualLocation.region, expectedLocation.region)
            XCTAssertEqual(actualLocation.country, expectedLocation.country)
        } else {
            XCTAssertNil(actualEndpointProfile.location)
        }

        if endpointProfile.user != nil {
            guard let actualUser = actualEndpointProfile.user else {
                XCTFail("actual User is nil")
                return
            }

            let expectedUser = endpointProfile.user
            XCTAssertEqual(actualUser.userId, expectedUser?.userId)
        } else {
            XCTAssertNil(actualEndpointProfile.user)
        }
    }

    public func verifyAddAttribute(_ theValue: [Any], forKey theKey: String) {
        XCTAssertEqual(addAttributeCalled, 1)
        XCTAssertNotNil(addAttributeValue)
        XCTAssertEqual(addAttributeValue?.count, theValue.count)
        XCTAssertEqual(addAttributeKey, theKey)
    }

    public func verifyRemoveAttribute(forKey theKey: String) {
        XCTAssertEqual(removeAttributeCalled, 1)
        XCTAssertEqual(removeAttributeKey, theKey)
    }

    public func verifyAddMetric(_ theValue: NSNumber, forKey theKey: String) {
        XCTAssertEqual(addMetricCalled, 1)
        XCTAssertEqual(addMetricValue, theValue)
        XCTAssertEqual(addMetricKey, theKey)
    }

    public func verifyRemoveMetric(forKey theKey: String) {
        XCTAssertEqual(removeMetricCalled, 1)
        XCTAssertEqual(removeMetricKey, theKey)
    }
}

extension MockAWSPinpoint {
    public func verifyAddGlobalAttribute(_ theValue: String, forKey theKey: String) {
        XCTAssertEqual(addGlobalAttributeCalled, 1)

        XCTAssertEqual(addGlobalAttributeValue, theValue)
        XCTAssertEqual(addGlobalAttributeKey, theKey)
    }

    public func verifyAddGlobalAttribute(_ theValue: String, forKey theKey: String, forEventType theEventType: String) {
        XCTAssertEqual(addGlobalAttributeCalled, 1)

        XCTAssertEqual(addGlobalAttributeValue, theValue)
        XCTAssertEqual(addGlobalAttributeKey, theKey)
        XCTAssertEqual(addGlobalAttributeEventType, theEventType)
    }

    public func verifyAddGlobalMetric(_ theValue: NSNumber, forKey theKey: String) {
        XCTAssertEqual(addGlobalMetricCalled, 1)

        XCTAssertEqual(addGlobalMetricValue, theValue)
        XCTAssertEqual(addGlobalMetricKey, theKey)
    }

    public func verifyAddGlobalMetric(_ theValue: NSNumber, forKey theKey: String, forEventType theEventType: String) {
        XCTAssertEqual(addGlobalMetricCalled, 1)

        XCTAssertEqual(addGlobalMetricValue, theValue)
        XCTAssertEqual(addGlobalMetricKey, theKey)
        XCTAssertEqual(addGlobalMetricEventType, theEventType)
    }

    public func verifyRemoveGlobalAttribute(forKey theKey: String) {
        XCTAssertEqual(removeGlobalAttributeCalled, 1)

        XCTAssertEqual(removeGlobalAttributeKey, theKey)
    }

    public func verifyRemoveGlobalAttribute(forKey theKey: String, forEventType theEventType: String) {
        XCTAssertEqual(removeGlobalAttributeCalled, 1)
        XCTAssertEqual(removeGlobalAttributeKey, theKey)
        XCTAssertEqual(removeGlobalAttributeEventType, theEventType)
    }

    public func verifyRemoveGlobalMetric(forKey theKey: String) {
        XCTAssertEqual(removeGlobalMetricCalled, 1)
        XCTAssertEqual(removeGlobalMetricKey, theKey)
    }

    public func verifyRemoveGlobalMetric(forKey theKey: String, forEventType theEventType: String) {
        XCTAssertEqual(removeGlobalMetricCalled, 1)
        XCTAssertEqual(removeGlobalMetricKey, theKey)
        XCTAssertEqual(removeglobalMetricEventType, theEventType)
    }

    public func verifyRecord(_ theEvent: AWSPinpointEvent) {
        XCTAssertEqual(recordCalled, 1)
        XCTAssertEqual(recordEvent, theEvent)
    }

    public func verifyCreateEvent(withEventType theEventType: String) {
        XCTAssertEqual(createEventCalled, 1)
        XCTAssertEqual(createEventEventType, theEventType)
    }

    public func verifyCreateAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                                   with product: SKProduct) {
        XCTAssertEqual(createAppleMonetizationEventCalled, 1)
        XCTAssertEqual(createAppleMonetizationEventTransaction, transaction)
        XCTAssertEqual(createAppleMonetizationEventProduct, product)
    }

    public func verifyCreateVirtualMonetizationEvent(withProductId theProductId: String,
                                                     withItemPrice theItemPrice: Double,
                                                     withQuantity theQuantity: Int,
                                                     withCurrency theCurrency: String) {
        XCTAssertEqual(createVirtualMonetizationEventCalled, 1)
        XCTAssertEqual(createVirtualMonetizationEventProductId, theProductId)
        XCTAssertEqual(createVirtualMonetizationEventItemPrice, theItemPrice)
        XCTAssertEqual(createVirtualMonetizationEventQuantity, theQuantity)
        XCTAssertEqual(createVirtualMonetizationEventCurrency, theCurrency)
    }

    public func verifySubmitEvents() {
        XCTAssertEqual(submitEventsCalled, 1)
    }
}
