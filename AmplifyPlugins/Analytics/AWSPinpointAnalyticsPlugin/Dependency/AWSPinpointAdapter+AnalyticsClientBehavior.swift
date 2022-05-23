//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
import StoreKit

extension AWSPinpointAdapter: AWSPinpointAnalyticsClientBehavior {
    func addGlobalAttribute(_ theValue: String, forKey theKey: String) {
        pinpoint.analyticsClient.addGlobalAttribute(theValue, forKey: theKey)
    }

    func addGlobalAttribute(_ theValue: String, forKey theKey: String, forEventType theEventType: String) {
        pinpoint.analyticsClient.addGlobalAttribute(theValue, forKey: theKey, forEventType: theEventType)
    }

    func addGlobalMetric(_ theValue: Double, forKey theKey: String) {
        pinpoint.analyticsClient.addGlobalMetric(theValue, forKey: theKey)
    }

    func addGlobalMetric(_ theValue: Double, forKey theKey: String, forEventType theEventType: String) {
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

    func record(_ theEvent: PinpointEvent) async throws {
        try await pinpoint.analyticsClient.record(theEvent)
    }

    func createEvent(withEventType theEventType: String) -> PinpointEvent {
        return pinpoint.analyticsClient.createEvent(withEventType: theEventType)
    }

    func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                      with product: SKProduct) -> PinpointEvent {
        pinpoint.analyticsClient.createAppleMonetizationEvent(with: transaction, with: product)
    }

    func createVirtualMonetizationEvent(withProductId theProductId: String,
                                        withItemPrice theItemPrice: Double,
                                        withQuantity theQuantity: Int,
                                        withCurrency theCurrency: String) -> PinpointEvent {
        pinpoint.analyticsClient.createVirtualMonetizationEvent(withProductId: theProductId,
                                                                withItemPrice: theItemPrice,
                                                                withQuantity: theQuantity,
                                                                withCurrency: theCurrency)
    }

    func submitEvents() async throws -> [PinpointEvent] {
        let result = try await pinpoint.analyticsClient.submitEvents()
        return result
    }

    // TODO: Do we need two methods? 
    func submitEvents() async throws {
        _ = try await pinpoint.analyticsClient.submitEvents()
    }
}
