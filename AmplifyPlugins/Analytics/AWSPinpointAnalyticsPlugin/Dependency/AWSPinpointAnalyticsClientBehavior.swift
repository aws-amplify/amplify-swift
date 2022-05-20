//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
import StoreKit

/// Methods copied from `AWSPinpointAnalyticsClient`
protocol AWSPinpointAnalyticsClientBehavior {
    /**
     Returns the `AWSPinpointEventRecorder` which is the low level client used to record events to local storage.

     You can use it for more advanced fine grained control over the events recorded.

     @returns the `AWSPinpointEventRecorder` used for storing events.
     */
    // var eventRecorder: AWSPinpointEventRecorder { get }

    /**
     Adds the specified attribute to all subsequent recorded events.

     @param theValue the value of the attribute.
     @param theKey the name of the attribute to add.
     */
    func addGlobalAttribute(_ theValue: String, forKey theKey: String)

    /**
     Adds the specified attribute to all subsequent recorded events with the specified event type.

     @param theValue the value of the attribute.
     @param theKey the name of the attribute to add.
     @param theEventType the type of events to add the attribute to.
     */
    func addGlobalAttribute(_ theValue: String, forKey theKey: String, forEventType theEventType: String)

    /**
     Adds the specified metric to all subsequent recorded events.

     @param theValue the value of the metric
     @param theKey the name of the metric to add
     */
    func addGlobalMetric(_ theValue: Double, forKey theKey: String)

    /**
     Adds the specified metric to all subsequent recorded events with the specified event type.

     @param theValue the value of the metric
     @param theKey the name of the metric to add
     @param theEventType the type of events to add the metric to
     */
    func addGlobalMetric(_ theValue: Double, forKey theKey: String, forEventType theEventType: String)

    /**
     Removes the specified attribute. All subsequent recorded events will no longer have this global attribute.

     @param theKey the key of the attribute to remove
     */
    func removeGlobalAttribute(forKey theKey: String)

    /**
     Removes the specified attribute. All subsequent recorded events with the specified event type will no longer
     have this global attribute.

     @param theKey the key of the attribute to remove
     @param theEventType the type of events to remove the attribute from
     */
    func removeGlobalAttribute(forKey theKey: String, forEventType theEventType: String)

    /**
     Removes the specified metric. All subsequent recorded events will no longer have this global metric.

     @param theKey the key of the metric to remove
     */
    func removeGlobalMetric(forKey theKey: String)

    /**
     Removes the specified metric. All subsequent recorded events with the specified event type will no longer have
     this global metric.

     @param theKey the key of the metric to remove
     @param theEventType the type of events to remove the metric from
     */
    func removeGlobalMetric(forKey theKey: String, forEventType theEventType: String)

    /**
     Records the specified AWSPinpointEvent to the local filestore.

     @param theEvent The AWSPinpointEvent to persist

     @return AWSTask - task.result is always nil.
     */
    func record(_ theEvent: PinpointEvent) async throws

    /**
     Create an AWSPinpointEvent with the specified theEventType

     @param theEventType the type of event to create

     @returns an AWSPinpointEvent with the specified event type
     */
    func createEvent(withEventType theEventType: String) -> PinpointEvent

    /**
     Create an Apple monetization AWSPinpointEvent of type "_monetization.purchase" with the specified parameters.

     @param transaction A SKPaymentTransaction object returned from an IAP
     @param product A SKProduct object of the an IAP

     @returns an AWSPinpointEvent with the specified event type
     */
    func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                      with product: SKProduct) -> PinpointEvent

    /**
     Create a Virtual monetization AWSPinpointEvent of type "_monetization.purchase" with the specified parameters.

     @param theProductId A product identifier for your virtual monitization event
     @param theItemPrice An item price for your virtual monitization event
     @param theQuantity A quantity of how many products sold for your virtual monitization event
     @param theCurrency The currency for your virtual monitization event

     @returns an AWSPinpointEvent with the specified event type
     */
    func createVirtualMonetizationEvent(withProductId theProductId: String,
                                        withItemPrice theItemPrice: Double,
                                        withQuantity theQuantity: Int,
                                        withCurrency theCurrency: String) -> PinpointEvent

    /**
     Submits all recorded events to Pinpoint.
     Events are automatically submitted when the application goes into the background.

     @return AWSTask - task.result contains successful submitted events.
     */
    func submitEvents() async throws -> [PinpointEvent]

    /**
     Submits all recorded events to Pinpoint.
     Events are automatically submitted when the application goes into the background.

     @param completionBlock The block to be executed after submission has completed.

     @return AWSTask - task.result is always nil.
     */
    func submitEvents() async throws
}
