//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import ClientRuntime
import Foundation

/// AnalyticsEventRecording saves and submits pinpoint events
protocol AnalyticsEventRecording {
    /// Saves a pinpoint event to storage
    /// - Parameter event: A PinpointEvent
    func save(_ event: PinpointEvent) throws
    /// Submit all locally stored events
    /// - Returns: A collection of events submitted to Pinpoint
    func submitAllEvents() async throws -> [PinpointEvent]
}

/// An AnalyticsEventRecording implementation that stores and submits pinpoint events
class EventRecorder: AnalyticsEventRecording {
    let appId: String
    let storage: AnalyticsEventStorage
    let pinpointClient: PinpointClientProtocol
    let endpointClient: EndpointClientBehaviour
    private var submittedEvents: [PinpointEvent] = []

    /// Initializer for Event Recorder
    /// - Parameters:
    ///   - appId: The Pinpoint App Id
    ///   - storage: A storage object that conforms to AnalyticsEventStorage
    ///   - pinpointClient: A Pinpoint client
    ///   - endpointClient: An EndpointClientBehaviour client
    init(appId: String, storage: AnalyticsEventStorage, pinpointClient: PinpointClientProtocol, endpointClient: EndpointClientBehaviour) throws {
        self.appId = appId
        self.storage = storage
        self.pinpointClient = pinpointClient
        self.endpointClient = endpointClient
        try self.storage.initializeStorage()
        try self.storage.deleteDirtyEvents()
        try self.storage.checkDiskSize(limit: Constants.pinpointClientByteLimitDefault)
    }

    /// Saves a pinpoint event to storage
    /// - Parameter event: A PinpointEvent
    func save(_ event: PinpointEvent) throws {
        try storage.saveEvent(event)
        try self.storage.checkDiskSize(limit: Constants.pinpointClientByteLimitDefault)
    }

    /// Submit all locally stored events in batches
    /// If event submission fails, the event retry count is increment otherwise event is marked dirty and available for deletion in the local storage if retry count exceeds 3
    /// If event submission succeeds, the event is removed from local storage
    /// - Returns: A collection of events submitted to Pinpoint
    func submitAllEvents() async throws -> [PinpointEvent] {
        return try await submitEvents()
    }

    private func submitEvents() async throws -> [PinpointEvent] {
        let publicEndpoint = try await getPublicEndpoint()
        let eventsBatch = try getBatchRecords()
        if eventsBatch.count > 0 {
            try await submit(eventsBatch, publicEndpoint: publicEndpoint)
        }
        return submittedEvents
    }

    private func getBatchRecords() throws -> [PinpointEvent] {
        return try storage.getEventsWith(limit: Constants.maxEventsSubmittedPerBatch)
    }

    private func submit(_ eventBatch: [PinpointEvent], publicEndpoint: PinpointClientTypes.PublicEndpoint) async throws {
        try await submit(pinpointEvents: eventBatch, publicEndpoint: publicEndpoint)
        try storage.removeFailedEvents()
        let nextEventsBatch = try getBatchRecords()
        if nextEventsBatch.count > 0 {
            try await submit(nextEventsBatch, publicEndpoint: publicEndpoint)
        }
    }

    private func submit(pinpointEvents: [PinpointEvent], publicEndpoint: PinpointClientTypes.PublicEndpoint) async throws {
        var clientEvents = [String: PinpointClientTypes.Event]()
        for event in pinpointEvents {
            clientEvents[UUID().uuidString] = event.clientTypeEvent
            let eventsBatch = PinpointClientTypes.EventsBatch(endpoint: publicEndpoint, events: clientEvents)
            let batchItem: [String: PinpointClientTypes.EventsBatch] = [self.appId: eventsBatch]
            let eventRequest = PinpointClientTypes.EventsRequest(batchItem: batchItem)
            let putEventsInput = PutEventsInput(applicationId: self.appId, eventsRequest: eventRequest)

            do {
                _ = try await pinpointClient.putEvents(input: putEventsInput)
                try self.storage.deleteEvent(eventId: event.id)
                self.submittedEvents.append(event)
            } catch {
                if let sdkError = error as? SdkError<Any>, sdkError.isRetryable {
                    try self.storage.incrementEventRetry(eventId: event.id)
                } else {
                    try self.storage.setDirtyEvent(eventId: event.id)
                }
            }
        }
    }

    private func getPublicEndpoint() async throws -> PinpointClientTypes.PublicEndpoint {
        let endpointProfile = await endpointClient.currentEndpointProfile()
        let channelType: PinpointClientTypes.ChannelType = endpointProfile.isDebug ? .apns : .apnsSandbox
        let optOut = endpointProfile.isOptOut ? EndpointClient.Constants.OptOut.all : EndpointClient.Constants.OptOut.none
        let publicEndpoint = PinpointClientTypes.PublicEndpoint(
            address: endpointProfile.endpointId,
            attributes: endpointProfile.attributes,
            channelType: channelType,
            demographic: endpointProfile.demographic,
            effectiveDate: endpointProfile.effectiveDate.iso8601FractionalSeconds(),
            location: endpointProfile.location,
            metrics: endpointProfile.metrics,
            optOut: optOut,
            user: endpointProfile.user)
        return publicEndpoint
    }
}

extension EventRecorder {
    private struct Constants {
        static let maxEventsSubmittedPerBatch = 100
        static let pinpointClientByteLimitDefault = 5 * 1024 * 1024 // 5MB
        static let pinpointClientBatchRecordByteLimitDefault = 512 * 1024 // 0.5MB
        static let pinpointClientBatchRecordByteLimitMax = 4 * 1024 * 1024 // 4MB
    }
}
