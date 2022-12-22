//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
@testable import Amplify
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

class AnalyticsEventStorageTests: XCTestCase {
    private let databaseName = "TestDatabase"
    private let eventCountStatement = "SELECT COUNT(*) FROM Event"
    private let dirtyEventCountStatement = "SELECT COUNT(*) FROM DirtyEvent"
    private var adapter: SQLStorageProtocol!
    private var storage: AnalyticsEventSQLStorage!
    private var fileManager: MockFileManager!

    override func setUp() {
        do {
            cleanup()
            fileManager = MockFileManager(fileName: databaseName)
            adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName, fileManager: fileManager)
            storage = AnalyticsEventSQLStorage(dbAdapter: adapter)
            try storage.initializeStorage()

            let insertEventStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            let insertDirtyEventStatement = """
                INSERT INTO DirtyEvent (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let attributes = ["key1": "value1", "key2": "value2", "key3": "value3"]
            let metrics = ["key1": 1.0, "key2": 2.0]
            let archiver = AmplifyArchiver()
            let encodedAttributes = try archiver.encode(attributes)
            let attributesBlob = Blob(bytes: [UInt8](encodedAttributes))
            let encodedMetrics = try archiver.encode(metrics)
            let metricsBlob = Blob(bytes: [UInt8](encodedMetrics))
            let basicEvent: [Binding] = [1, attributesBlob, "eventType", metricsBlob, "2022-06-10T18:50:20.618Z", 1, "2022-06-10T17:00:20.618Z", "2022-06-10T17:10:20.618Z", 1654904585, 0, 0]
            let failedWithMaxRetry: [Binding] = [2, attributesBlob, "eventType", metricsBlob, "2022-06-9T18:50:20.618Z", 2, "2022-06-9T17:00:20.618Z", "2022-06-9T17:10:20.618Z", 1654818185, 0, 4]
            let dirtyEvent: [Binding] = [3, attributesBlob, "eventType", metricsBlob, "2022-06-8T18:50:20.618Z", 3, "2022-06-8T17:00:20.618Z", "2022-06-8T17:10:20.618Z", 1654731785, 1, 3]
            let dirtyEvent2: [Binding] = [4, attributesBlob, "eventType", metricsBlob, "2022-06-7T18:50:20.618Z", 4, "2022-06-7T17:00:20.618Z", "2022-06-7T17:10:20.618Z", 1654645385, 1, 3]
            let eventWithDirtyFlag: [Binding] = [5, attributesBlob, "eventType", metricsBlob, "2022-06-6T18:50:20.618Z", 5, "2022-06-6T17:00:20.618Z", "2022-06-6T17:10:20.618Z", 1654558985, 1, 1]

            _ = try adapter.executeQuery(insertEventStatement, basicEvent)
            _ = try adapter.executeQuery(insertEventStatement, failedWithMaxRetry)
            _ = try adapter.executeQuery(insertDirtyEventStatement, dirtyEvent)
            _ = try adapter.executeQuery(insertDirtyEventStatement, dirtyEvent2)

            _ = try adapter.executeQuery(insertEventStatement, eventWithDirtyFlag)
        } catch {
            XCTFail("Failed to remove SQLite as part of test setup")
        }
    }

    override func tearDown() {
        cleanup()
    }

    private func cleanup() {
        fileManager = nil
        adapter = nil
        storage = nil
    }

    /// - Given: a local storage
    /// - When: disk usage is under the limit
    /// - Then: keep records intact
    func testDiskUsageCheckUnderLimit() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            XCTAssertEqual(dirtyEventcount, 2)

            try storage.checkDiskSize(limit: 10000000)

            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            XCTAssertEqual(dirtyEventcount, 2)
        } catch {
            XCTFail("Failed to test disk usage under limit")
        }
    }

    /// - Given: a local storage
    /// - When: delete is called for a given event id
    /// - Then: event is deleted from local storage
    func testDeleteEvent() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            try storage.deleteEvent(eventId: "1")
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 2)
        } catch {
            XCTFail("Failed to delete event")
        }
    }

    /// - Given: a local storage
    /// - When: delete is called with an invalid event id
    /// - Then: no events are deleted
    func testInvalidDeleteEvent() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            try storage.deleteEvent(eventId: "200")
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
        } catch {
            XCTFail("Failed to delete event")
        }
    }

    /// - Given: a local storage
    /// - When: delete dirty events is called
    /// - Then: all dirty events are removed
    func testDeleteDirtyEvents() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            XCTAssertEqual(dirtyEventcount, 2)

            try storage.deleteDirtyEvents()

            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 2)
            XCTAssertEqual(dirtyEventcount, 0)
        } catch {
            XCTFail("Failed to delete all dirty events")
        }
    }

    /// - Given: a local storage
    /// - When: delete oldest event is called
    /// - Then: the oldest event in the event table is removed
    func testDeleteOldestEvent() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            XCTAssertEqual(dirtyEventcount, 2)

            try storage.deleteOldestEvent()

            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 2)
            XCTAssertEqual(dirtyEventcount, 2)

            let events = try storage.getEventsWith(limit: 5)
            XCTAssertEqual(events.count, 2)
            XCTAssertTrue(events.contains(where: { $0.id ==  "1"}))
            XCTAssertTrue(events.contains(where: { $0.id ==  "2"}))
        } catch {
            XCTFail("Failed to delete oldest event")
        }
    }

    /// - Given: a local storage
    /// - When: get a list of of events given a limit is called
    /// - Then: a list of events is returned
    func testGetEventsWithLimit() {
        do {

            let events = try storage.getEventsWith(limit: 5)
            XCTAssertEqual(events.count, 3)
            XCTAssertTrue(events.contains(where: { $0.id ==  "1"}))
            XCTAssertTrue(events.contains(where: { $0.id ==  "2"}))
            XCTAssertTrue(events.contains(where: { $0.id ==  "5"}))
        } catch {
            XCTFail("Failed to get events")
        }
    }

    /// - Given: a local storage
    /// - When: get events with limit is called
    /// - Then: a event with the list of event has expect properties and attributes
    func testPinpointEventConversion() {
        do {
            let expectedSessionStartTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2022-06-10T17:00:20.618+0000")
            let expectedSessionStopTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2022-06-10T17:10:20.618+0000")
            let events = try storage.getEventsWith(limit: 5)
            let latestEvent = events.first(where: { $0.id == "1" })
            XCTAssertNotNil(latestEvent)
            XCTAssertEqual(latestEvent?.eventType, "eventType")
            XCTAssertEqual(latestEvent?.eventDate.millisecondsSince1970, 1654887020618)
            XCTAssertEqual(latestEvent?.session.sessionId, "1")
            XCTAssertEqual(latestEvent?.session.startTime, expectedSessionStartTime)
            XCTAssertEqual(latestEvent?.session.stopTime, expectedSessionStopTime)
            XCTAssertEqual(latestEvent?.session.duration, 600000)
            XCTAssertEqual(latestEvent?.attributes.count, 3)
            XCTAssertEqual(latestEvent?.attributes["key2"], "value2")
            XCTAssertEqual(latestEvent?.metrics.count, 2)
            XCTAssertEqual(latestEvent?.metrics["key2"], 2.0)
        } catch {
            XCTFail("Failed to convert elements to event")
        }
    }

    /// - Given: a local storage
    /// - When: delete all event si called
    /// - Then: all events in the events table are removed
    func testDeleteAllEvents() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)

            try storage.deleteAllEvents()

            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 0)
        } catch {
            XCTFail("Failed to delete all events")
        }
    }

    /// - Given: a local storage
    /// - When: increment even retry count on a given event id
    /// - Then: the retry count for the event is incremented by one
    func testIncrementEventRetry() {
        do {
            let eventId = "1"
            let selectStatement = "SELECT * FROM Event WHERE id = ?"
            var retryCount: Int64?
            var results = try adapter.executeQuery(selectStatement, [eventId])
            var result = results.makeIterator().next()
            retryCount = result?[10] as? Int64
            XCTAssertEqual(retryCount, 0)

            try storage.incrementEventRetry(eventId: eventId)

            results = try adapter.executeQuery(selectStatement, [eventId])
            result = results.makeIterator().next()
            retryCount = result?[10] as? Int64
            XCTAssertEqual(retryCount, 1)
        } catch {
            XCTFail("Failed to increment event retry count")
        }
    }

    /// - Given: a local storage
    /// - When: remove failed events is called
    /// - Then: all events with retry count > 3 are removed from the event table and added to the dirty event table
    func testRemoveFailedEvents() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 3)
            XCTAssertEqual(dirtyEventcount, 2)

            try storage.removeFailedEvents()

            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertEqual(eventcount, 1)
            XCTAssertEqual(dirtyEventcount, 4)

            let events = try storage.getEventsWith(limit: 5)
            XCTAssertEqual(events.count, 1)
            XCTAssertTrue(events.contains(where: { $0.id ==  "1"}))
        } catch {
            XCTFail("Failed to remove failed events")
        }
    }

    /// - Given: a local storage
    /// - When: set the dirty flag on the even table is called for a given event id
    /// - Then: the dirty flag on the given event id is set to 1
    func testSetDirtyEvent() {
        do {
            let eventId = "2"
            let selectStatement = "SELECT * FROM Event WHERE id = ?"
            var dirtyFlag: Int64?
            var results = try adapter.executeQuery(selectStatement, [eventId])
            var result = results.makeIterator().next()
            dirtyFlag = result?[9] as? Int64
            XCTAssertEqual(dirtyFlag, 0)

            try storage.setDirtyEvent(eventId: eventId)

            results = try adapter.executeQuery(selectStatement, [eventId])
            result = results.makeIterator().next()
            dirtyFlag = result?[9] as? Int64
            XCTAssertEqual(dirtyFlag, 1)
        } catch {
            XCTFail("Failed to set dirty flag on event")
        }
    }

    /// - Given: a local storage
    /// - When: save event is called given a Pinpoint event
    /// - Then: the event is save with correct attributes/properties in the event table
    func testSaveEvent() {
        do {
            let expectedSessionStartTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2022-06-11T17:00:20.618+0000")
            let expectedSessionStopTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2022-06-11T17:10:20.618+0000")

            var events = try storage.getEventsWith(limit: 5)
            var latestEvent = events.first(where: { $0.id == "6" })
            XCTAssertNil(latestEvent)

            let session = PinpointSession(sessionId: "6", startTime: expectedSessionStartTime!, stopTime: expectedSessionStopTime)
            let event = PinpointEvent(id: "6", eventType: "newEventType", eventDate: expectedSessionStartTime!, session: session)
            event.addAttribute("testValue", forKey: "testKey")
            event.addMetric(3.0, forKey: "testKey")
            try storage.saveEvent(event)

            events = try storage.getEventsWith(limit: 5)
            latestEvent = events.first(where: { $0.id == "6" })
            XCTAssertNotNil(latestEvent)
            XCTAssertEqual(latestEvent?.eventType, "newEventType")
            XCTAssertEqual(latestEvent?.eventDate, expectedSessionStartTime)
            XCTAssertEqual(latestEvent?.session.sessionId, "6")
            XCTAssertEqual(latestEvent?.session.startTime, expectedSessionStartTime)
            XCTAssertEqual(latestEvent?.session.stopTime, expectedSessionStopTime)
            XCTAssertEqual(latestEvent?.session.duration, 600000)
            XCTAssertEqual(latestEvent?.attributes.count, 1)
            XCTAssertEqual(latestEvent?.attributes["testKey"], "testValue")
            XCTAssertEqual(latestEvent?.metrics.count, 1)
            XCTAssertEqual(latestEvent?.metrics["testKey"], 3.0)
        } catch {
            XCTFail("Failed to save a new event")
        }
    }

    func testUpdateEvents() throws {
        try storage.deleteAllEvents()
        let eventType = "_session.start"
        let expectedSessionStartTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2050-06-11T17:00:20.618+0000")
        let expectedSessionStopTime = DateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: "2050-06-11T17:10:20.618+0000")
        let session = PinpointSession(sessionId: "session-id",
                                      startTime: expectedSessionStartTime!,
                                      stopTime: expectedSessionStopTime)
        let event1 = PinpointEvent(id: "event-1",
                                   eventType: eventType,
                                   session: session)
        let event2 = PinpointEvent(id: "event-2",
                                   eventType: eventType,
                                   session: session)

        let notASessionStartEvent = PinpointEvent(id: "event-3",
                                                  eventType: "another-event-type",
                                                  session: session)

        let attributes = ["attr1": "value1", "attr2": "value2"]

        try storage.saveEvent(event1)
        try storage.saveEvent(event2)
        try storage.saveEvent(notASessionStartEvent)

        try storage.updateEvents(ofType: eventType,
                                 withSessionId: session.sessionId,
                                 setAttributes: attributes)

        let savedEvents = try storage.getEventsWith(limit: 3)

        XCTAssertEqual(savedEvents[0].id, event1.id)
        XCTAssertEqual(savedEvents[1].id, event2.id)
        XCTAssertEqual(savedEvents[0].attributes, attributes)
        XCTAssertEqual(savedEvents[1].attributes, attributes)

        // event-3 should not have been updated
        XCTAssertEqual(savedEvents[2].id, notASessionStartEvent.id)
        XCTAssertNotEqual(savedEvents[2].attributes, attributes)
    }
}
