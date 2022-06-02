//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import StoreKit

actor AnalyticsClient: InternalPinpointClient {
    private let eventRecorder: AnalyticsEventRecording
    unowned let context: PinpointContext
    private lazy var globalAttributes: [String: String] = [:]
    private lazy var globalMetrics: [String: Double] = [:]
    private lazy var eventTypeAttributes: [String: [String: String]] = [:]
    private lazy var eventTypeMetrics: [String: [String: Double]] = [:]
    
    init(eventRecorder: AnalyticsEventRecording = EventRecorder(),
         context: PinpointContext) {
        self.eventRecorder = eventRecorder
        self.context = context
    }
    
    // MARK: - Attributes & Metrics
    func addGlobalAttribute(_ attribute: String, forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalAttributes[key] = attribute
    }
    
    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        eventTypeAttributes[eventType]?[key] = attribute
    }

    func addGlobalMetric(_ metric: Double, forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalMetrics[key] = metric
    }
    
    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        eventTypeMetrics[eventType]?[key] = metric
    }
    
    func removeGlobalAttribute(forKey key: String) {
        globalAttributes[key] = nil
    }
    
    func removeGlobalAttribute(forKey key: String, forEventType eventType: String) {
        eventTypeAttributes[eventType]?[key] = nil
    }
    
    func removeGlobalMetric(forKey key: String) {
        globalMetrics[key] = nil
    }
    
    func removeGlobalMetric(forKey key: String, forEventType eventType: String) {
        eventTypeMetrics[eventType]?[key] = nil
    }
    
    // MARK: - Monetization events
    nonisolated func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                                  with product: SKProduct) -> PinpointEvent {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = product.priceLocale
        numberFormatter.numberStyle = .currency
        numberFormatter.isLenient = true

        return createMonetizationEvent(withStore: Constants.PurchaseEvent.appleStore,
                                       productId: product.productIdentifier,
                                       quantity: transaction.payment.quantity,
                                       itemPrice: product.price.doubleValue,
                                       currencyCode: product.priceLocale.currencyCode,
                                       formattedItemPrice: numberFormatter.string(from: product.price),
                                       transactionId: transaction.transactionIdentifier)
    }

    nonisolated func createVirtualMonetizationEvent(withProductId productId: String,
                                                    withItemPrice itemPrice: Double,
                                                    withQuantity quantity: Int,
                                                    withCurrency currency: String) -> PinpointEvent {
        return createMonetizationEvent(withStore: Constants.PurchaseEvent.virtual,
                                       productId: productId,
                                       quantity: quantity,
                                       itemPrice: itemPrice,
                                       currencyCode: currency)
    }
    
    private nonisolated func createMonetizationEvent(withStore store: String,
                                                     productId: String,
                                                     quantity: Int,
                                                     itemPrice: Double,
                                                     currencyCode: String?,
                                                     formattedItemPrice: String? = nil,
                                                     priceLocale: Locale? = nil,
                                                     transactionId: String? = nil) -> PinpointEvent {
        let monetizationEvent = PinpointEvent(eventType: Constants.PurchaseEvent.name,
                                              session: context.sessionTracker.currentSession)
        monetizationEvent.addAttribute(store,
                                       forKey: Constants.PurchaseEvent.Keys.store)
        monetizationEvent.addAttribute(productId,
                                       forKey: Constants.PurchaseEvent.Keys.productId)
        monetizationEvent.addMetric(quantity,
                                    forKey: Constants.PurchaseEvent.Keys.quantity)
        monetizationEvent.addMetric(itemPrice,
                                    forKey: Constants.PurchaseEvent.Keys.itemPrice)

        if let currencyCode = currencyCode {
            monetizationEvent.addAttribute(currencyCode,
                                           forKey: Constants.PurchaseEvent.Keys.currency)
        }

        if let formattedItemPrice = formattedItemPrice {
            monetizationEvent.addAttribute(formattedItemPrice,
                                           forKey: Constants.PurchaseEvent.Keys.priceFormatted)
        }

        if let transactionId = transactionId {
            monetizationEvent.addAttribute(transactionId,
                                           forKey: Constants.PurchaseEvent.Keys.transactionId)
        }

        return monetizationEvent
    }

    // MARK: - Event recording
    nonisolated func createEvent(withEventType eventType: String) -> PinpointEvent {
        precondition(!eventType.isEmpty, "Event types must be at least 1 character in length.")
        return PinpointEvent(eventType: eventType,
                             session: context.sessionTracker.currentSession)
    }
    
    func record(_ event: PinpointEvent) async throws {
        // Add event type attributes
        if let eventAttributes = eventTypeAttributes[event.eventType] {
            for (key, attribute) in eventAttributes {
                event.addAttribute(attribute, forKey: key)
            }
        }

        // Add event type metrics
        if let eventMetrics = eventTypeMetrics[event.eventType] {
            for (key, metric) in eventMetrics {
                event.addMetric(metric, forKey: key)
            }
        }

        // Add global attributes
        for (key, attribute) in globalAttributes {
            event.addAttribute(attribute, forKey: key)
        }

        // Add global metrics
        for (key, metric) in globalMetrics {
            event.addMetric(metric, forKey: key)
        }

        try await eventRecorder.save(event)
    }
    
    @discardableResult
    func submitEvents() async throws -> [PinpointEvent] {
        return try await eventRecorder.submitAllEvents()
    }
}

extension AnalyticsClient {
    private struct Constants {
        struct PurchaseEvent {
            static let name = "_monetization.purchase"
            static let appleStore = "Apple"
            static let virtual = "Virtual"

            struct Keys {
                static let productId = "_product_id"
                static let quantity = "_quantity"
                static let itemPrice = "_item_price"
                static let priceFormatted = "_item_price_formatted"
                static let currency = "_currency"
                static let store = "_store"
                static let transactionId = "_transaction_id"
            }
        }
    }
}

extension Date {
    typealias Millisecond = Int64

    var utcTimeMillis: Millisecond {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
