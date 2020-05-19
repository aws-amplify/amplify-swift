//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension AWSPinpointAdapter: AWSPinpointAnalyticsClientBehavior {
    func addGlobalAttribute(_ theValue: String, forKey theKey: String) {
        pinpoint.analyticsClient.addGlobalAttribute(theValue, forKey: theKey)
    }

    func addGlobalAttribute(_ theValue: String, forKey theKey: String, forEventType theEventType: String) {
        pinpoint.analyticsClient.addGlobalAttribute(theValue, forKey: theKey, forEventType: theEventType)
    }

    func addGlobalMetric(_ theValue: NSNumber, forKey theKey: String) {
        pinpoint.analyticsClient.addGlobalMetric(theValue, forKey: theKey)
    }

    func addGlobalMetric(_ theValue: NSNumber, forKey theKey: String, forEventType theEventType: String) {
        pinpoint.analyticsClient.addGlobalMetric(theValue, forKey: theKey, forEventType: theEventType)
    }

    func removeGlobalAttribute(forKey theKey: String) {
        pinpoint.analyticsClient.removeGlobalAttribute(forKey: theKey)
    }

    func removeGlobalAttribute(forKey theKey: String, forEventType _: String) {
        pinpoint.analyticsClient.removeGlobalAttribute(forKey: theKey)
    }

    func removeGlobalMetric(forKey theKey: String) {
        pinpoint.analyticsClient.removeGlobalMetric(forKey: theKey)
    }

    func removeGlobalMetric(forKey theKey: String, forEventType theEventType: String) {
        pinpoint.analyticsClient.removeGlobalMetric(forKey: theKey, forEventType: theEventType)
    }

    func record(_ theEvent: AWSPinpointEvent) -> AWSTask<AnyObject> {
        pinpoint.analyticsClient.record(theEvent)
    }

    func createEvent(withEventType theEventType: String) -> AWSPinpointEvent {
        pinpoint.analyticsClient.createEvent(withEventType: theEventType)
    }

    func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                      with product: SKProduct) -> AWSPinpointEvent {
        pinpoint.analyticsClient.createAppleMonetizationEvent(with: transaction, with: product)
    }

    func createVirtualMonetizationEvent(withProductId theProductId: String,
                                        withItemPrice theItemPrice: Double,
                                        withQuantity theQuantity: Int,
                                        withCurrency theCurrency: String) -> AWSPinpointEvent {
        pinpoint.analyticsClient.createVirtualMonetizationEvent(withProductId: theProductId,
                                                                withItemPrice: theItemPrice,
                                                                withQuantity: theQuantity,
                                                                withCurrency: theCurrency)
    }

    func submitEvents() -> AWSTask<AnyObject> {
        pinpoint.analyticsClient.submitEvents()
    }

    func submitEvents(completionBlock: @escaping AWSPinpointCompletionBlock) -> AWSTask<AnyObject> {
        pinpoint.analyticsClient.submitEvents(completionBlock: completionBlock)
    }
}
