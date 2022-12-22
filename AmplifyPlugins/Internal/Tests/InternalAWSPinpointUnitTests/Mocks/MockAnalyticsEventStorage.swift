//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class MockAnalyticsEventStorage: AnalyticsEventStorage {
    var deletedEvent: String = ""
    var deleteDirtyEventCallCount = 0
    var initializeStorageCallCount = 0
    var deleteOldestEventCallCount = 0
    var deleteAllEventsCallCount = 0
    var updateEventsCallCount = 0
    var removedFailedEventsCallCount = 0
    var eventRetryDictionary = [String: Int]()
    var dirtyEventDictionary = [String: Int]()
    var events = [PinpointEvent]()
    var checkDiskSizeCallCount = 0

    func deleteEvent(eventId: String) throws {
        deletedEvent = eventId
    }

    func deleteDirtyEvents() throws {
        deleteDirtyEventCallCount += 1
    }

    func initializeStorage() throws {
        initializeStorageCallCount += 1
    }

    func deleteOldestEvent() throws {
        deleteOldestEventCallCount += 1
    }

    func deleteAllEvents() throws {
        deleteAllEventsCallCount += 1
    }
    func updateEvents(ofType: String,
                      withSessionId: PinpointSession.SessionId,
                      setAttributes: [String: String]) throws {
        updateEventsCallCount += 1
    }

    func getEventsWith(limit: Int) throws -> [PinpointEvent] {
        return events
    }

    func incrementEventRetry(eventId: String) throws {
        guard let retryCount = eventRetryDictionary[eventId] else {
            eventRetryDictionary[eventId] = 1
            return
        }
        eventRetryDictionary[eventId] = retryCount + 1
    }

    func removeFailedEvents() throws {
        removedFailedEventsCallCount += 1
    }

    func saveEvent(_ event: PinpointEvent) throws {
        events.append(event)
    }

    func setDirtyEvent(eventId: String) throws {
        dirtyEventDictionary[eventId] = 1
    }

    func checkDiskSize(limit: Byte) throws {
        checkDiskSizeCallCount += 1
    }
}
