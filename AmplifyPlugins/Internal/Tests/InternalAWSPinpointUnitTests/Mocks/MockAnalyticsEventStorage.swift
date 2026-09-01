//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class MockAnalyticsEventStorage: AnalyticsEventStorage {
    var deletedEvent: String = ""
    // Boxed: incremented from a `@Sendable` mock closure.
    let deleteEventCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let deleteDirtyEventCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let initializeStorageCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let deleteOldestEventCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let deleteAllEventsCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let updateEventsCallCount = AtomicValue(initialValue: 0)
    // Boxed: incremented from a `@Sendable` mock closure.
    let removedFailedEventsCallCount = AtomicValue(initialValue: 0)
    var eventRetryDictionary = [String: Int]()
    var dirtyEventDictionary = [String: Int]()
    var events = [PinpointEvent]()
    // Boxed: incremented from a `@Sendable` mock closure.
    let checkDiskSizeCallCount = AtomicValue(initialValue: 0)

    func deleteEvent(eventId: String) throws {
        deletedEvent = eventId
        _ = deleteEventCallCount.increment()
        events.removeAll { $0.id == eventId }
    }

    func deleteDirtyEvents() throws {
        _ = deleteDirtyEventCallCount.increment()
    }

    func initializeStorage() throws {
        _ = initializeStorageCallCount.increment()
    }

    func deleteOldestEvent() throws {
        _ = deleteOldestEventCallCount.increment()
    }

    func deleteAllEvents() throws {
        _ = deleteAllEventsCallCount.increment()
    }
    func updateEvents(
        ofType: String,
        withSessionId: PinpointSession.SessionId,
        setAttributes: [String: String]
    ) throws {
        _ = updateEventsCallCount.increment()
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
        _ = removedFailedEventsCallCount.increment()
    }

    func saveEvent(_ event: PinpointEvent) throws {
        events.append(event)
    }

    func setDirtyEvent(eventId: String) throws {
        dirtyEventDictionary[eventId] = 1
    }

    func checkDiskSize(limit: Byte) throws {
        _ = checkDiskSizeCallCount.increment()
    }

    var updateSessionCount = 0
    func updateSession(_ session: PinpointSession) throws {
        updateSessionCount += 1
    }
}
