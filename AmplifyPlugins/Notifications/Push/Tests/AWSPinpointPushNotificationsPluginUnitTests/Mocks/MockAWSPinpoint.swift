//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
@testable import AWSPinpointPushNotificationsPlugin
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import XCTest

class MockAWSPinpoint: AWSPinpointBehavior {
    var pinpointClient: PinpointClientProtocol = try! PinpointClient(region: "us-east-1")

    var createEventCount = 0
    var mockedCreatedEvent: PinpointEvent?
    func createEvent(withEventType eventType: String) -> PinpointEvent {
        createEventCount += 1
        let event = PinpointEvent(
            eventType: eventType,
            session: .init(appId: "applicationId", uniqueId: "endpointId")
        )
        mockedCreatedEvent = event
        return event
    }

    var setRemoteGlobalAttributesCount = 0
    func setRemoteGlobalAttributes(_ attributes: [String : String]) async {
        setRemoteGlobalAttributesCount += 1
    }

    var recordCount = 0
    func record(_ event: PinpointEvent) async throws {
        recordCount += 1
    }

    var currentEndpointProfileCount = 0
    var mockedPinpointEndpointProfile = PinpointEndpointProfile(
        applicationId: "applicationId",
        endpointId: "endpointId"
    )
    func currentEndpointProfile() async -> PinpointEndpointProfile {
        currentEndpointProfileCount += 1
        return mockedPinpointEndpointProfile
    }

    var updateEndpointCount = 0
    var updatedPinpointEndpointProfile: PinpointEndpointProfile?
    func updateEndpoint(with endpointProfile: PinpointEndpointProfile,
                        source: AWSPinpointSource) async throws {
        updateEndpointCount += 1
        updatedPinpointEndpointProfile = endpointProfile
    }

    func addGlobalProperty(_ value: AnalyticsPropertyValue, forKey key: String) async {}
    func removeGlobalProperty(_ value: AnalyticsPropertyValue, forKey key: String) async {}
    func startTrackingSessions(backgroundTimeout: TimeInterval) {}
    func submitEvents() async throws -> [PinpointEvent] { [] }
    func setAutomaticSubmitEventsInterval(_ interval: TimeInterval, onSubmit: ((Result<[PinpointEvent], Error>) -> Void)?) {}
}

