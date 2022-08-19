//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

extension PinpointContext: AWSPinpointBehavior {

    var pinpointClient: PinpointClientProtocol {
        analyticsClient.pinpointClient
    }

    func createEvent(withEventType eventType: String) -> PinpointEvent {
        analyticsClient.createEvent(withEventType: eventType)
    }

    func record(_ event: PinpointEvent) async throws {
        try await analyticsClient.record(event)
    }

    @discardableResult func submitEvents() async throws -> [PinpointEvent] {
        try await analyticsClient.submitEvents()
    }

    func currentEndpointProfile() async -> PinpointEndpointProfile {
        await endpointClient.currentEndpointProfile()
    }

    func update(_ endpointProfile: PinpointEndpointProfile) async throws {
        try await endpointClient.updateEndpointProfile(with: endpointProfile)
    }

    func removeGlobalProperty(withValue value: AnalyticsPropertyValue, forKey: String) {
        Task {
            if value is String || value is Bool {
                await analyticsClient.removeGlobalAttribute(forKey: forKey)
            } else if value is Int || value is Double {
                await analyticsClient.removeGlobalMetric(forKey: forKey)
            }
        }
    }

    func addGlobalProperty(withValue value: AnalyticsPropertyValue, forKey: String) {
        Task {
            if let value = value as? String {
                await analyticsClient.addGlobalAttribute(value, forKey: forKey)
            } else if let value = value as? Int {
                await analyticsClient.addGlobalMetric(Double(value), forKey: forKey)
            } else if let value = value as? Double {
                await analyticsClient.addGlobalMetric(value, forKey: forKey)
            } else if let value = value as? Bool {
                await analyticsClient.addGlobalAttribute(String(value), forKey: forKey)
            }
        }
    }
}
