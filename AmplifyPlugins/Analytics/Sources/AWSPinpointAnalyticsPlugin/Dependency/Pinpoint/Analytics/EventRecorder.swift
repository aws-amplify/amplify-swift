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

    /// Updates attributes of the events with the provided session id
    /// - Parameters:
    ///   - ofType: event type
    ///   - withSessionId: session identifier
    ///   - setAttributes: event attributes
    func updateAttributesOfEvents(ofType: String,
                                  withSessionId: PinpointSession.SessionId,
                                  setAttributes: [String: String]) throws

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
    init(appId: String,
         storage: AnalyticsEventStorage,
         pinpointClient: PinpointClientProtocol,
         endpointClient: EndpointClientBehaviour) throws {
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
        log.verbose("saveEvent: \(event)")
        try storage.saveEvent(event)
        try self.storage.checkDiskSize(limit: Constants.pinpointClientByteLimitDefault)
    }

    func updateAttributesOfEvents(ofType eventType: String,
                                  withSessionId sessionId: PinpointSession.SessionId,
                                  setAttributes attributes: [String: String]) throws {
        try self.storage.updateEvents(ofType: eventType,
                                      withSessionId: sessionId,
                                      setAttributes: attributes)
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
        } else {
            log.verbose("No events to submit")
        }
        return submittedEvents
    }

    private func getBatchRecords() throws -> [PinpointEvent] {
        return try storage.getEventsWith(limit: Constants.maxEventsSubmittedPerBatch)
    }

    private func processBatch(_ eventBatch: [PinpointEvent], endpointProfile: PinpointEndpointProfile) async throws {
        log.verbose("Submitting batch with \(eventBatch.count) events ")
        do {
            try await submit(pinpointEvents: eventBatch, endpointProfile: endpointProfile)
        } catch {
            // If the submit operation fails, attempt to update the database regardless and rethrow the error
            try storage.removeFailedEvents()
            throw error
        }
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
            log.verbose("PutEventsInput: \(putEventsInput)")
            let response = try await pinpointClient.putEvents(input: putEventsInput)
            log.verbose("PutEventsOutputResponse received: \(response)")
            guard let results = response.eventsResponse?.results else {
                let errorMessage = "Unexpected response from server when attempting to submit events."
                log.error(errorMessage)
                throw AnalyticsError.unknown(errorMessage)
            }

            let endpointResponseMap = results.compactMap { $0.value.endpointItemResponse }
            for endpointResponse in endpointResponseMap {
                if HttpStatusCode.accepted.rawValue == endpointResponse.statusCode {
                    log.verbose("EndpointProfile updated successfully.")
                } else {
                    log.error("Unable to update EndpointProfile. Error: \(endpointResponse.message ?? "Unknown")")
                }
            }

            let eventsResponseMap = results.compactMap { $0.value.eventsItemResponse }
            for (eventId, eventResponse) in eventsResponseMap.flatMap({ $0 }) {
                guard let event = pinpointEventsById[eventId] else { continue }
                let responseMessage = eventResponse.message ?? "Unknown"
                if HttpStatusCode.accepted.rawValue == eventResponse.statusCode,
                   Constants.acceptedResponseMessage == responseMessage {
                    // On successful submission, add the event to the list of submitted events and delete it from the local storage
                    log.verbose("Successful submit for event with id \(eventId)")
                    submittedEvents.append(event)
                    deleteEvent(eventId: eventId)
                } else if HttpStatusCode.badRequest.rawValue == eventResponse.statusCode {
                    // On bad request responses, mark the event as dirty
                    log.error("Server rejected submission of event. Event with id \(eventId) will be discarded. Error: \(responseMessage)")
                    setDirtyEvent(eventId: eventId)
                } else {
                    // On other failures, increment the event retry counter
                    incrementEventRetry(eventId: eventId)
                    let retryMessage: String
                    if event.retryCount < Constants.maxNumberOfRetries {
                        retryMessage = "Event will be retried"
                    } else {
                        retryMessage = "Event will be discarded because it exceeded its max retry attempts"
                    }
                    log.verbose("Submit attempt #\(event.retryCount + 1) for event with id \(eventId) failed.")
                    log.error("Unable to successfully deliver event with id \(eventId) to the server. \(retryMessage). Error: \(responseMessage)")
                }
            }

            // If no event was submitted successfuly, consider the operation a failure
            // and throw an error so that consumers can be notified
            if submittedEvents.isEmpty, !pinpointEvents.isEmpty {
                let errorMessage = "Unable to submit \(pinpointEvents.count) events"
                log.error(errorMessage)
                throw AnalyticsError.unknown(errorMessage)
            }
        } catch let analyticsError as AnalyticsError {
            // This is a known error explicitly thrown inside the do/catch block, so just rethrow it so it can be handled by the consumer
            throw analyticsError
        } catch {
            // This means all events were rejected
            if isConnectivityError(error) {
                // Connectivity errors should be retried indefinitely, so we won't update the database
                log.error("Unable to submit \(pinpointEvents.count) events. Error: \(AnalyticsPluginErrorConstant.deviceOffline.errorDescription)")
            } else if isErrorRetryable(error) {
                // For retryable errors, increment the events retry count
                log.error("Unable to submit \(pinpointEvents.count) events. Error: \(errorDescription(error)).")
                incrementRetryCounter(for: pinpointEvents)
            } else {
                // For remaining errors, mark events as dirty
                log.error("Server rejected the submission of \(pinpointEvents.count) events. Error: \(errorDescription(error)).")
                markEventsAsDirty(pinpointEvents)
            }

            // Rethrow the original error so it can be handled by the consumer
            throw error
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
    
    private func errorDescription(_ error: Error) -> String {
        switch error {
        case let sdkPutEventsOutputError as SdkError<PutEventsOutputError>:
            return sdkPutEventsOutputError.errorDescription
        case let sdkError as SdkError<Error>:
            return sdkError.errorDescription
        default:
            return error.localizedDescription
        }
    }
    
    private func isConnectivityError(_ error: Error) -> Bool {
        switch error {
        case let clientError as ClientError:
            if case .networkError(_) = clientError {
                return true
            }
            return false
        case let sdkPutEventsOutputError as SdkError<PutEventsOutputError>:
            return sdkPutEventsOutputError.isConnectivityError
        case let sdkError as SdkError<Error>:
            return sdkError.isConnectivityError
        case let error as NSError:
            let networkErrorCodes = [
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorNotConnectedToInternet
            ]
            return networkErrorCodes.contains(where: { $0 == error.code })
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
    
    private func markEventsAsDirty(_ events: [PinpointEvent]) {
        events.forEach { setDirtyEvent(eventId: $0.id) }
    }


    private func incrementEventRetry(eventId: String) {
        retry(onErrorMessage: "Unable to update retry count for event with id \(eventId).") {
            try storage.incrementEventRetry(eventId: eventId)
        }
    }
    
    private func incrementRetryCounter(for events: [PinpointEvent]) {
        events.forEach { incrementEventRetry(eventId: $0.id) }
    }

    private func retry(times: Int = Constants.defaultNumberOfRetriesForStorageOperations,
                       onErrorMessage: String,
                       _ closure: () throws -> Void) {
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
        static let maxEventsSubmittedPerBatch = 100
        static let pinpointClientByteLimitDefault = 5 * 1024 * 1024 // 5MB
        static let pinpointClientBatchRecordByteLimitDefault = 512 * 1024 // 0.5MB
        static let pinpointClientBatchRecordByteLimitMax = 4 * 1024 * 1024 // 4MB
        static let acceptedResponseMessage = "Accepted"
        static let defaultNumberOfRetriesForStorageOperations = 1
        static let maxNumberOfRetries = 3
    }
}
