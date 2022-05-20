//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import StoreKit

class AnalyticsClient: InternalPinpointClient {
    private let eventRecorder: EventRecorder
    private var globalAttributes: [String: String] = [:]
    private var globalMetrics: [String: Double] = [:]
        
    override init(context: PinpointContext) {
        eventRecorder = EventRecorder()
        super.init(context: context)
    }
    
    // MARK: - Attributes & Metrics
    func addGlobalAttribute(_ attribute: String, forKey key: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func addGlobalAttribute(_ attribute: String, forKey key: String, forEventType eventType: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }

    func addGlobalMetric(_ metric: Double, forKey key: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func addGlobalMetric(_ metric: Double, forKey key: String, forEventType eventType: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func removeGlobalAttribute(forKey key: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func removeGlobalAttribute(forKey key: String, forEventType eventType: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func removeGlobalMetric(forKey key: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func removeGlobalMetric(forKey key: String, forEventType eventType: String) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    
    // MARK: - Monetization events
    func createAppleMonetizationEvent(with transaction: SKPaymentTransaction,
                                      with product: SKProduct) -> PinpointEvent {
        // TODO: Implement
        fatalError("Not yet implemented")
    }

    func createVirtualMonetizationEvent(withProductId theProductId: String,
                                        withItemPrice theItemPrice: Double,
                                        withQuantity theQuantity: Int,
                                        withCurrency theCurrency: String) -> PinpointEvent {
        // TODO: Implement
        fatalError("Not yet implemented")
    }

    // MARK: - Event recording

    func createEvent(withEventType eventType: String) -> PinpointEvent {
        return PinpointEvent(eventType: eventType,
                             eventTyimestamp: Date().timeIntervalSince1970 * 1000,
                             session: context.sessionTracker.currentSession)
    }
    
    func record(_ event: PinpointEvent) {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
    
    func submitEvents() async throws -> [PinpointEvent] {
        // TODO: Implement
        fatalError("Not yet implemented")
    }
}
