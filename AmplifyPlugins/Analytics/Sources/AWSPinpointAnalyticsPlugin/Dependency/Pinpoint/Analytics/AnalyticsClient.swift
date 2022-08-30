//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import StoreKit
import Amplify
import AWSPinpoint

protocol AnalyticsClientBehaviour: Actor {
    nonisolated var pinpointClient: PinpointClientProtocol { get }

    func addGlobalAttribute(_ attribute: String, forKey key: String)
    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String)
    func addGlobalMetric(_ metric: Double, forKey key: String)
    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String)
    func removeGlobalAttribute(forKey key: String)
    func removeGlobalAttribute(forKey key: String, forEventType eventType: String)
    func removeGlobalMetric(forKey key: String)
    func removeGlobalMetric(forKey key: String, forEventType eventType: String)
    func record(_ event: PinpointEvent) async throws

    func setGlobalEventSourceAttributes(_ attributes: [String: Any]) throws
    func removeAllGlobalEventSourceAttributes()

    @discardableResult func submitEvents() async throws -> [PinpointEvent]

    nonisolated func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                      with product: SKProduct) -> PinpointEvent
    nonisolated func createVirtualMonetizationEvent(withProductId productId: String,
                                                    withItemPrice itemPrice: Double,
                                                    withQuantity quantity: Int,
                                        withCurrency currency: String) -> PinpointEvent
    nonisolated func createEvent(withEventType eventType: String) -> PinpointEvent

}

typealias SessionProvider = () -> PinpointSession

actor AnalyticsClient: AnalyticsClientBehaviour {
    private let eventRecorder: AnalyticsEventRecording
    private let sessionProvider: SessionProvider
    private lazy var globalAttributes: PinpointEventAttributes = [:]
    private lazy var globalMetrics: PinpointEventMetrics = [:]
    // TODO: review this type
    private lazy var globalEventSourceAttributes: [String: Any] = [:]
    private lazy var eventTypeAttributes: [String: PinpointEventAttributes] = [:]
    private lazy var eventTypeMetrics: [String: PinpointEventMetrics] = [:]

    init(eventRecorder: AnalyticsEventRecording,
         sessionProvider: @escaping SessionProvider) {
        self.eventRecorder = eventRecorder
        self.sessionProvider = sessionProvider
    }
    
    // Actors no longer use 'convenience' for inits. This is a warning in swift 5.7 and an error in swift 6+.
    // However, 'convenience' is required to build with swift <5.7
#if swift(>=5.7)
    init(applicationId: String,
         pinpointClient: PinpointClientProtocol,
         endpointClient: EndpointClientBehaviour,
         sessionProvider: @escaping SessionProvider) throws
    {
        let dbAdapter = try SQLiteLocalStorageAdapter(prefixPath: Constants.eventRecorderStoragePathPrefix,
                                                      databaseName: applicationId)
        let eventRecorder = try EventRecorder(appId: applicationId,
                                              storage: AnalyticsEventSQLStorage(dbAdapter: dbAdapter),
                                              pinpointClient: pinpointClient, endpointClient: endpointClient)
        
        self.init(eventRecorder: eventRecorder, sessionProvider: sessionProvider)
    }
#else
    convenience init(applicationId: String,
                     pinpointClient: PinpointClientProtocol,
                     endpointClient: EndpointClientBehaviour,
                     sessionProvider: @escaping SessionProvider) throws {
        let dbAdapter = try SQLiteLocalStorageAdapter(prefixPath: Constants.eventRecorderStoragePathPrefix,
                                                      databaseName: applicationId)
        let eventRecorder = try EventRecorder(appId: applicationId,
                                              storage: AnalyticsEventSQLStorage(dbAdapter: dbAdapter),
                                              pinpointClient: pinpointClient, endpointClient: endpointClient)
        
        self.init(eventRecorder: eventRecorder, sessionProvider: sessionProvider)
    }
#endif
    
    nonisolated var pinpointClient: PinpointClientProtocol {
        return eventRecorder.pinpointClient
    }

    // MARK: - Attributes & Metrics
    func addGlobalAttribute(_ attribute: String, forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalAttributes[key] = attribute
    }

    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        eventTypeAttributes[eventType, default: [:]][key] = attribute
    }

    func addGlobalMetric(_ metric: Double, forKey key: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        globalMetrics[key] = metric
    }

    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String) {
        precondition(!key.isEmpty, "Attributes and metrics must have a valid key")
        eventTypeMetrics[eventType, default: [:]][key] = metric
    }

    func setGlobalEventSourceAttributes(_ attributes: [String: Any]) throws {
        guard let attributes = attributes as? [String: String] else {
            return
        }
        globalEventSourceAttributes = attributes
        let sessionId = self.sessionProvider().sessionId

        try eventRecorder.updateAttributesOfEvents(ofType: SessionClient.Constants.Events.start,
                                                   withSessionId: sessionId,
                                                   setAttributes: attributes)
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

    func removeAllGlobalEventSourceAttributes() {
        for key in globalEventSourceAttributes.keys {
            removeGlobalAttribute(forKey: key)
        }
        globalEventSourceAttributes = [:]
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
                                              session: sessionProvider())
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
                             session: sessionProvider())
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

        // Add event source attributes
        for (key, attribute) in globalEventSourceAttributes {
            // TODO: review this
            if let attribute = attribute as? String {
                event.addAttribute(attribute, forKey: key)
            }
        }

        try eventRecorder.save(event)
    }

    @discardableResult
    func submitEvents() async throws -> [PinpointEvent] {
        return try await eventRecorder.submitAllEvents()
    }
}

extension AnalyticsClient: DefaultLogger { }

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

        static let eventRecorderStoragePathPrefix = "com/amazonaws/AWSPinpointRecorder/"
    }

    typealias PinpointEventAttributes = [String: String]
    typealias PinpointEventMetrics = [String: Double]
}
