//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpoint
import AwsCommonRuntimeKit
@testable import Amplify
import ClientRuntime
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class EventRecorderTests: XCTestCase {
    var recorder: AnalyticsEventRecording!
    var storage: MockAnalyticsEventStorage!
    var pinpointClient: MockPinpointClient!
    var endpointClient: MockEndpointClient!

    override func setUp() {
        pinpointClient = MockPinpointClient()
        endpointClient = MockEndpointClient()
        storage = MockAnalyticsEventStorage()
        do {
            recorder = try EventRecorder(appId: "appId", storage: storage, pinpointClient: pinpointClient, endpointClient: endpointClient)
        } catch {
            XCTFail("Failed to setup EventRecorderTests")
        }
    }
    
    override func tearDown() {
        pinpointClient = nil
        endpointClient = nil
        storage = nil
        recorder = nil
    }

    /// - Given: a event recorder
    /// - When: instance is constructed
    /// - Then: storage initializatin is called followed by disk size check and dirty event removal
    func testRecorderInitilization() {
        XCTAssertEqual(storage.initializeStorageCallCount, 1)
        XCTAssertEqual(storage.deleteDirtyEventCallCount, 1)
        XCTAssertEqual(storage.checkDiskSizeCallCount, 1)
    }

    /// - Given: a event recorder
    /// - When: a new pinpoint event is aved
    /// - Then: the event is saved to storage followed by a disk size check
    func testSaveEvent() async {
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        let event = PinpointEvent(id: "1", eventType: "eventType", eventDate: Date(), session: session)

        XCTAssertEqual(storage.events.count, 0)
        XCTAssertEqual(storage.checkDiskSizeCallCount, 1)

        do {
            try await recorder.save(event)
        } catch {
            XCTFail("Failed to save events")
        }

        XCTAssertEqual(storage.events.count, 1)
        XCTAssertEqual(event, storage.events[0])
        XCTAssertEqual(storage.checkDiskSizeCallCount, 2)
    }
    
    /// - Given: a event recorder with events saved in the local storage
    /// - When: submitAllEvents is invoked and successful
    /// - Then: the events are removed from the local storage
    func testSubmitAllEvents_withSuccess_shouldRemoveEventsFromStorage() async throws {
        Amplify.Logging.logLevel = .verbose
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        storage.events = [
            .init(id: "1", eventType: "eventType1", eventDate: Date(), session: session),
            .init(id: "2", eventType: "eventType2", eventDate: Date(), session: session)
        ]

        pinpointClient.putEventsResult = .success(.init(eventsResponse: .init(results: [
            "endpointId": PinpointClientTypes.ItemResponse(
                endpointItemResponse: .init(message: "Accepted", statusCode: 202),
                eventsItemResponse: [
                    "1": .init(message: "Accepted", statusCode: 202),
                    "2": .init(message: "Accepted", statusCode: 202)
                ]
            )
        ])))
        let events = try await recorder.submitAllEvents()
        
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(pinpointClient.putEventsCount, 1)
        XCTAssertTrue(storage.events.isEmpty)
        XCTAssertEqual(storage.deleteEventCallCount, 2)
    }
    
    /// - Given: a event recorder with events saved in the local storage with active and stopped sessions
    /// - When: submitAllEvents is invoked
    /// - Then: the input is generated accordingly by including duration only for the stopped session
    func testSubmitAllEvents_withActiveAndStoppedSessions_shouldGenerateRightInput() async throws {
        let activeSession = PinpointSession(
            sessionId: "active",
            startTime: Date(),
            stopTime: nil
        )
        let stoppedSession = PinpointSession(
            sessionId: "stopped",
            startTime: Date().addingTimeInterval(-10),
            stopTime: Date()
        )
        storage.events = [
            .init(id: "1", eventType: "eventType1", eventDate: Date(), session: activeSession),
            .init(id: "2", eventType: "eventType2", eventDate: Date(), session: stoppedSession)
        ]

        _ = try? await recorder.submitAllEvents()
        XCTAssertEqual(pinpointClient.putEventsCount, 1)
        let input = try XCTUnwrap(pinpointClient.putEventsLastInput)
        let batchItem = try XCTUnwrap(input.eventsRequest?.batchItem?.first?.value as? PinpointClientTypes.EventsBatch)
        let events = try XCTUnwrap(batchItem.events)
        XCTAssertEqual(events.count, 2)
        XCTAssertNotNil(events["1"]?.session, "Expected session for eventType1")
        XCTAssertNil(events["1"]?.session?.duration, "Expected nil session duration for eventType")
        XCTAssertNotNil(events["2"]?.session, "Expected session for eventType2")
        XCTAssertNotNil(events["2"]?.session?.duration, "Expected session duration for eventType2")
    }

    /// - Given: a event recorder with events saved in the local storage
    /// - When: submitAllEvents is invoked and fails with a non-retryable error
    /// - Then: the events are marked as dirty
    func testSubmitAllEvents_withRetryableError_shouldSetEventsAsDirty() async throws {
        Amplify.Logging.logLevel = .verbose
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        let event1 = PinpointEvent(id: "1", eventType: "eventType1", eventDate: Date(), session: session)
        let event2 = PinpointEvent(id: "2", eventType: "eventType2", eventDate: Date(), session: session)
        storage.events = [ event1, event2 ]
        pinpointClient.putEventsResult = .failure(NonRetryableError())
        do {
            let events = try await recorder.submitAllEvents()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(pinpointClient.putEventsCount, 1)
            XCTAssertEqual(storage.events.count, 2)
            XCTAssertEqual(storage.deleteEventCallCount, 0)
            XCTAssertEqual(storage.eventRetryDictionary.count, 0)
            XCTAssertEqual(storage.dirtyEventDictionary.count, 2)
            XCTAssertEqual(storage.dirtyEventDictionary["1"], 1)
            XCTAssertEqual(storage.dirtyEventDictionary["2"], 1)
        }
    }

    /// - Given: a event recorder with events saved in the local storage
    /// - When: submitAllEvents is invoked and fails with a retryable error
    /// - Then: the events' retry count is increased
    func testSubmitAllEvents_withRetryableError_shouldIncreaseRetryCount() async throws {
        Amplify.Logging.logLevel = .verbose
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        let event1 = PinpointEvent(id: "1", eventType: "eventType1", eventDate: Date(), session: session)
        let event2 = PinpointEvent(id: "2", eventType: "eventType2", eventDate: Date(), session: session)
        storage.events = [ event1, event2 ]
        pinpointClient.putEventsResult = .failure(RetryableError())
        do {
            let events = try await recorder.submitAllEvents()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(pinpointClient.putEventsCount, 1)
            XCTAssertEqual(storage.events.count, 2)
            XCTAssertEqual(storage.deleteEventCallCount, 0)
            XCTAssertEqual(storage.eventRetryDictionary.count, 2)
            XCTAssertEqual(storage.eventRetryDictionary["1"], 1)
            XCTAssertEqual(storage.eventRetryDictionary["2"], 1)
            XCTAssertEqual(storage.dirtyEventDictionary.count, 0)
        }
    }

    /// - Given: a event recorder with events saved in the local storage
    /// - When: submitAllEvents is invoked and fails with a connectivity error
    /// - Then: the events are not removed from the local storage
    func testSubmitAllEvents_withConnectivityError_shouldNotIncreaseRetryCount_andNotSetEventsAsDirty() async throws {
        Amplify.Logging.logLevel = .verbose
        let session = PinpointSession(sessionId: "1", startTime: Date(), stopTime: nil)
        let event1 = PinpointEvent(id: "1", eventType: "eventType1", eventDate: Date(), session: session)
        let event2 = PinpointEvent(id: "2", eventType: "eventType2", eventDate: Date(), session: session)
        storage.events = [ event1, event2 ]
        pinpointClient.putEventsResult = .failure(ConnectivityError())
        do {
            let events = try await recorder.submitAllEvents()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(pinpointClient.putEventsCount, 1)
            XCTAssertEqual(storage.events.count, 2)
            XCTAssertEqual(storage.deleteEventCallCount, 0)
            XCTAssertEqual(storage.eventRetryDictionary.count, 0)
            XCTAssertEqual(storage.dirtyEventDictionary.count, 0)
        }
    }
}

private struct RetryableError: Error, ModeledError {
    static var typeName = "RetriableError"
    static var fault = ErrorFault.client
    static var isRetryable = true
    static var isThrottling = false
}

private struct NonRetryableError: Error, ModeledError {
    static var typeName = "RetriableError"
    static var fault = ErrorFault.client
    static var isRetryable = false
    static var isThrottling = false
}

private class ConnectivityError: NSError {
    init() {
        super.init(
            domain: "ConnectivityError",
            code: NSURLErrorNotConnectedToInternet
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
