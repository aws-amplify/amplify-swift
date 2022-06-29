//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import ClientRuntime
import Foundation

/// AnalyticsEventRecording saves and submits pinpoint events
protocol AnalyticsEventRecording {
    var pinpointClient: PinpointClientProtocol { get }

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
        submittedEvents = []
        let eventsBatch = try getBatchRecords()
        if eventsBatch.count > 0 {
            let endpointProfile = await endpointClient.currentEndpointProfile()
            try await processBatch(eventsBatch, endpointProfile: endpointProfile)
        }
        return submittedEvents
    }

    private func getBatchRecords() throws -> [PinpointEvent] {
        return try storage.getEventsWith(limit: Constants.maxEventsSubmittedPerBatch)
    }

    private func processBatch(_ eventBatch: [PinpointEvent], endpointProfile: PinpointEndpointProfile) async throws {
        try await submit(pinpointEvents: eventBatch, endpointProfile: endpointProfile)
        try storage.removeFailedEvents()
        let nextEventsBatch = try getBatchRecords()
        if nextEventsBatch.count > 0 {
            try await processBatch(nextEventsBatch, endpointProfile: endpointProfile)
        }
    }

    private func submit(pinpointEvents: [PinpointEvent],
                        endpointProfile: PinpointEndpointProfile) async throws {
        var clientEvents = [String: PinpointClientTypes.Event]()
        var pinpointEventsById = [String: PinpointEvent]()
        for event in pinpointEvents {
            clientEvents[event.id] = event.clientTypeEvent
            pinpointEventsById[event.id] = event
        }

        let publicEndpoint = endpointClient.convertToPublicEndpoint(endpointProfile)
        let eventsBatch = PinpointClientTypes.EventsBatch(endpoint: publicEndpoint,
                                                          events: clientEvents)
        let batchItem = [endpointProfile.endpointId: eventsBatch]
        let putEventsInput = PutEventsInput(applicationId: appId,
                                            eventsRequest: .init(batchItem: batchItem))

        do {
            let response = try await pinpointClient.putEvents(input: putEventsInput)
            guard let results = response.eventsResponse?.results else {
                log.error("Unexpected response from server when attempting to submit events.")
                return
            }

            let endpointResponseMap = results.compactMap { $0.value.endpointItemResponse }
            for endpointResponse in endpointResponseMap {
                if Constants.StatusCode.ok == endpointResponse.statusCode {
                    log.verbose("EndpointProfile updated successfully.")
                } else {
                    log.error("Unable to update EndpointProfile. Error: \(endpointResponse.message ?? "Unknown")")
                }
            }

            let eventsResponseMap = results.compactMap { $0.value.eventsItemResponse }
            for (eventId, eventResponse) in eventsResponseMap.flatMap({ $0 }) {
                guard let event = pinpointEventsById[eventId] else { continue }
                if Constants.StatusCode.ok == eventResponse.statusCode,
                   Constants.acceptedResponseMessage == eventResponse.message {
                    // On successful submission, add the event to the list of submitted events and delete it from the local storage
                    log.verbose("Successful submit for event with id \(eventId)")
                    submittedEvents.append(event)
                    deleteEvent(eventId: eventId)
                } else if Constants.StatusCode.badRequest == eventResponse.statusCode {
                    // Mark event as dirty
                    log.error("Server rejected submission of event. Event with id \(eventId) will be marked dirty.")
                    setDirtyEvent(eventId: eventId)
                } else {
                    // Mark event as retryable
                    log.warn("Unable to successfully deliver event with id \(eventId) to the server. It will be updated with retry count += 1.")
                    incrementEventRetry(eventId: eventId)
                }
            }
        } catch {
            // This means all events were rejected, so we will update them all in the local storage accodingly
            let isRetryable = isErrorRetryable(error)
            for event in pinpointEvents {
                if isRetryable {
                    try self.storage.incrementEventRetry(eventId: event.id)
                } else {
                    try self.storage.setDirtyEvent(eventId: event.id)
                }
            }
        }
    }

    private func isErrorRetryable(_ error: Error) -> Bool {
        switch error {
        case let clientError as ClientError:
            return clientError.isRetryable
        case let putEventsOutputError as PutEventsOutputError:
            return putEventsOutputError.isRetryable
        case let sdkPutEventsOutputError as SdkError<PutEventsOutputError>:
            return sdkPutEventsOutputError.isRetryable
        case let sdkError as SdkError<Error>:
            return sdkError.isRetryable
        default:
            return false
        }
    }

    private func deleteEvent(eventId: String) {
        retry(onErrorMessage: "Unable to delete event with id \(eventId).") {
            try storage.deleteEvent(eventId: eventId)
        }
    }

    private func setDirtyEvent(eventId: String) {
        retry(onErrorMessage: "Unable to mark event with id \(eventId) as dirty.") {
            try storage.setDirtyEvent(eventId: eventId)
        }
    }

    private func incrementEventRetry(eventId: String) {
        retry(onErrorMessage: "Unable to update retry count for event with id \(eventId).") {
            try storage.incrementEventRetry(eventId: eventId)
        }
    }

    private func retry(times: Int = 1, onErrorMessage: String, _ closure: () throws -> ()) {
        do {
            try closure()
        } catch {
            if times > 0 {
                log.verbose("\(onErrorMessage). Retrying.")
                retry(times: times - 1, onErrorMessage: onErrorMessage, closure)
            } else {
                log.error(onErrorMessage)
                log.error(error: error)
            }
        }
    }
}

extension EventRecorder: DefaultLogger {}

extension EventRecorder {
    private struct Constants {
        struct StatusCode {
            static let ok = 202
            static let badRequest = 400
        }

        static let maxEventsSubmittedPerBatch = 100
        static let pinpointClientByteLimitDefault = 5 * 1024 * 1024 // 5MB
        static let pinpointClientBatchRecordByteLimitDefault = 512 * 1024 // 0.5MB
        static let pinpointClientBatchRecordByteLimitMax = 4 * 1024 * 1024 // 4MB
        static let acceptedResponseMessage = "Accepted"
    }
}
