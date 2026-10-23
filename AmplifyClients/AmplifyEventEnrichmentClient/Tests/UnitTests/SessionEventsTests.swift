//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import Foundation
import XCTest

#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
@MainActor
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class SessionEventsTests: XCTestCase, @unchecked Sendable {

    /// Test that creating a client starts a session and closing it stops the session
    ///
    /// - Given: A client with autoSessionTracking enabled
    /// - When:
    ///    - It is closed without recording anything
    /// - Then:
    ///    - The sink receives a start and a stop for one session, the stop carrying
    ///      its stop timestamp and duration
    ///
    func testLaunchSendsStartAndCloseSendsStop() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink)

        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
        XCTAssertEqual(events[0].session.id, events[1].session.id)
        XCTAssertNil(events[0].session.stopTimestamp)
        XCTAssertNotNil(events[1].session.stopTimestamp)
        XCTAssertNotNil(events[1].session.duration)
    }

    /// Test that a client without autoSessionTracking sends nothing on its own
    ///
    /// - Given: A client with autoSessionTracking disabled
    /// - When:
    ///    - It is closed without starting a session
    /// - Then:
    ///    - The sink receives nothing
    ///
    func testNoSessionEventsWithoutAutoTracking() async {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, autoSessionTracking: false)

        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), [])
    }

    /// Test that recording with no running session sends its start first
    ///
    /// - Given: A client with autoSessionTracking disabled and no session started
    /// - When:
    ///    - An event is recorded, then the client is closed
    /// - Then:
    ///    - The sink receives the start, the record and the stop of one session
    ///
    func testRecordWithoutSessionSendsStartFirst() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, autoSessionTracking: false)

        let event = try await client.record("a")
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "a", "_session.stop"])
        XCTAssertEqual(events.map(\.session.id), Array(repeating: event.session.id, count: 3))
        assertSessionOrder(events)
    }

    /// Test that turning off session events sends only records
    ///
    /// - Given: A client with emitSessionEvents disabled
    /// - When:
    ///    - Events are recorded around a stop, then the client is closed
    /// - Then:
    ///    - The sink receives only the records, each still in its own session
    ///
    func testSessionEventsCanBeTurnedOff() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, emitSessionEvents: false)

        let first = try await client.record("a")
        await client.stopSession()
        let second = try await client.record("b")
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["a", "b"])
        XCTAssertNotEqual(first.session.id, second.session.id)
    }

    /// Test that records and boundaries reach the sink in call order
    ///
    /// - Given: A client with autoSessionTracking disabled
    /// - When:
    ///    - Sessions are started, restarted and stopped around recorded events
    /// - Then:
    ///    - The sink receives every event in call order, each record inside its session
    ///
    func testRecordsAndBoundariesArriveInCallOrder() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, autoSessionTracking: false)

        await client.startSession()
        let first = try await client.record("a")
        await client.startSession()
        let second = try await client.record("b")
        await client.stopSession()
        await client.close()

        let events = await sink.events
        XCTAssertEqual(
            events.map(\.eventType),
            ["_session.start", "a", "_session.stop", "_session.start", "b", "_session.stop"]
        )
        XCTAssertEqual(events.map(\.session.id), [
            first.session.id, first.session.id, first.session.id,
            second.session.id, second.session.id, second.session.id
        ])
        assertSessionOrder(events)
    }

    /// Test that concurrent records and session calls never break session order
    ///
    /// - Given: A client whose sink takes a little time per send
    /// - When:
    ///    - Records, restarts and stops are issued concurrently, then the client closes
    /// - Then:
    ///    - Every record lies inside its own session, boundaries alternate, sends never
    ///      overlap, and the last event is the final stop
    ///
    func testConcurrentCallsKeepSessionOrder() async throws {
        let sink = RecordingSink(delay: true)
        let client = makeClient(sink: sink)

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 60 {
                group.addTask {
                    switch index % 5 {
                    case 1: await client.startSession()
                    case 3: await client.stopSession()
                    default: _ = try? await client.record("event_\(index)")
                    }
                }
            }
        }
        await client.close()

        let events = await sink.events
        let maxInFlight = await sink.maxInFlight
        XCTAssertEqual(maxInFlight, 1)
        XCTAssertEqual(events.last?.eventType, "_session.stop")
        assertSessionOrder(events)
    }

    /// Test that record() returns only after the sink received its event
    ///
    /// - Given: A client whose sink holds every send until released
    /// - When:
    ///    - An event is recorded behind the launch start
    /// - Then:
    ///    - record() is still waiting while the start and then the event are held,
    ///      and returns once the event's send finishes
    ///
    func testRecordReturnsAfterItsSend() async throws {
        let sink = GatedSink()
        let client = makeClient(sink: sink)
        let returned = Flag()

        let recording = Task {
            let event = try await client.record("a")
            returned.set()
            return event
        }
        await sink.waitForSends(1)
        XCTAssertFalse(returned.isSet)
        await sink.release()
        await sink.waitForSends(2)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(returned.isSet)
        await sink.release()
        let event = try await recording.value

        let delivered = await sink.delivered
        XCTAssertEqual(delivered.map(\.eventType), ["_session.start", "a"])
        XCTAssertEqual(delivered.last?.eventId, event.eventId)

        await sink.releaseAll()
        await client.close()
    }

    /// Test that close() waits for everything queued, ending with the final stop
    ///
    /// - Given: A client whose sink holds every send, with a record queued
    /// - When:
    ///    - close() is called
    /// - Then:
    ///    - close() returns only after the final stop's send finishes, and the sink
    ///      receives the start, the record and the stop in that order
    ///
    func testCloseDrainsQueueBeforeReturning() async throws {
        let sink = GatedSink()
        let client = makeClient(sink: sink)
        let closed = Flag()

        let recording = Task { try await client.record("a") }
        await sink.waitForSends(1)
        let closing = Task {
            await client.close()
            closed.set()
        }
        await sink.release()
        await sink.waitForSends(2)
        await sink.release()
        await sink.waitForSends(3)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(closed.isSet)
        await sink.release()
        await closing.value
        _ = try await recording.value

        let delivered = await sink.delivered
        XCTAssertTrue(closed.isSet)
        XCTAssertEqual(delivered.map(\.eventType), ["_session.start", "a", "_session.stop"])
    }

    /// Test that nothing reaches the sink after the final stop
    ///
    /// - Given: A closed client with autoSessionTracking enabled
    /// - When:
    ///    - Events are recorded, sessions started and stopped, and lifecycle notifications posted
    /// - Then:
    ///    - The sink receives nothing more after the final stop
    ///
    func testNothingReachesSinkAfterFinalStop() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink)
        _ = try await client.record("a")
        await client.close()
        let afterClose = await sink.events

        _ = try? await client.record("b")
        await client.startSession()
        await client.stopSession()
        postBackgroundNotification()
        postForegroundNotification()
        try await Task.sleep(nanoseconds: 100_000_000)

        let events = await sink.events
        XCTAssertEqual(afterClose.map(\.eventType), ["_session.start", "a", "_session.stop"])
        XCTAssertEqual(events.map(\.eventId), afterClose.map(\.eventId))
    }

    /// Test that a background timeout sends a stop and the next foreground a start
    ///
    /// - Given: A client with a short session timeout
    /// - When:
    ///    - The app stays in the background past the timeout, then returns
    /// - Then:
    ///    - The old session's stop, stamped at the pause, is sent before the new session's start
    ///
    func testTimeoutStopThenResumeStart() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: 0.05)
        let first = try await client.record("a")

        let pauseTime = Date()
        postBackgroundNotification()
        try await Task.sleep(nanoseconds: 300_000_000)
        postForegroundNotification()
        try await Task.sleep(nanoseconds: 50_000_000)
        let second = try await client.record("b")
        await client.close()

        let events = await sink.events
        XCTAssertEqual(
            events.map(\.eventType),
            ["_session.start", "a", "_session.stop", "_session.start", "b", "_session.stop"]
        )
        XCTAssertEqual(events[2].session.id, first.session.id)
        XCTAssertEqual(events[3].session.id, second.session.id)
        let stopTimestamp = try XCTUnwrap(events[2].session.stopTimestamp)
        XCTAssertEqual(stopTimestamp.timeIntervalSince1970, pauseTime.timeIntervalSince1970, accuracy: 0.1)
        assertSessionOrder(events)
    }

    /// Test that back to back lifecycle changes reach the session manager in order
    ///
    /// - Given: A client with a zero session timeout, so every resume replaces the session
    /// - When:
    ///    - Background and foreground are posted back to back many times
    /// - Then:
    ///    - Every pair sends a stop and a start, in order, and the session ends active
    ///
    func testBackToBackLifecycleChangesArriveInOrder() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: 0)
        let pairs = 200

        for _ in 0 ..< pairs {
            postBackgroundNotification()
            postForegroundNotification()
        }
        let expected = 1 + 2 * pairs
        let deadline = Date().addingTimeInterval(2)
        while await sink.events.count < expected, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        let state = await client.sessionState
        XCTAssertEqual(state, .active)
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.count, expected + 1)
        XCTAssertEqual(
            events.map(\.eventType),
            ["_session.start"] + Array(repeating: ["_session.stop", "_session.start"], count: pairs).flatMap { $0 }
                + ["_session.stop"]
        )
        assertSessionOrder(events)
    }

    /// Test that a record after a burst of lifecycle changes joins the latest session
    ///
    /// - Given: A client with a zero session timeout, so every resume replaces the session
    /// - When:
    ///    - Background and foreground are posted back to back many times, then an event is recorded
    /// - Then:
    ///    - One session starts per resume and the record belongs to the last one
    ///
    func testRecordAfterLifecycleBurstJoinsLatestSession() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: 0)
        let pairs = 100

        for _ in 0 ..< pairs {
            postBackgroundNotification()
            postForegroundNotification()
        }
        let deadline = Date().addingTimeInterval(2)
        while await sink.events.count < 1 + 2 * pairs, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        let event = try await client.record("a")
        await client.close()

        let events = await sink.events
        let starts = events.filter { $0.eventType == "_session.start" }
        XCTAssertEqual(starts.count, 1 + pairs)
        XCTAssertEqual(starts.last?.session.id, event.session.id)
        assertSessionOrder(events)
    }

    /// Test that rapid restarts send one stop per start, in order
    ///
    /// - Given: A client with autoSessionTracking disabled
    /// - When:
    ///    - startSession() is called many times, sequentially and concurrently
    /// - Then:
    ///    - Every start is followed by its own stop before the next start
    ///
    func testQuickRestartsAlternate() async {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, autoSessionTracking: false)

        for _ in 0 ..< 5 {
            await client.startSession()
        }
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 15 {
                group.addTask { await client.startSession() }
            }
        }
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.count(where: { $0.eventType == "_session.start" }), 20)
        XCTAssertEqual(events.count(where: { $0.eventType == "_session.stop" }), 20)
        assertSessionOrder(events)
    }

    /// Test that a slow sink never drops, duplicates or overlaps sends
    ///
    /// - Given: A client whose sink takes a little time per send
    /// - When:
    ///    - Many events are recorded concurrently
    /// - Then:
    ///    - Each record returns after its own event was sent, every event is sent once,
    ///      and sends never overlap
    ///
    func testSlowSinkDeliversEachEventOnceInTurn() async throws {
        let sink = RecordingSink(delay: true)
        let client = makeClient(sink: sink)

        let sentBeforeReturn = await withTaskGroup(of: Bool.self) { group in
            for index in 0 ..< 30 {
                group.addTask {
                    guard let event = try? await client.record("event_\(index)") else { return false }
                    return await sink.events.contains { $0.eventId == event.eventId }
                }
            }
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        await client.close()

        let events = await sink.events
        let records = events.filter { !$0.eventType.hasPrefix("_session.") }
        let maxInFlight = await sink.maxInFlight
        XCTAssertEqual(sentBeforeReturn, Array(repeating: true, count: 30))
        XCTAssertEqual(Set(records.map(\.eventId)).count, 30)
        XCTAssertEqual(records.count, 30)
        XCTAssertEqual(maxInFlight, 1)
    }

    /// Test that session events carry the user ID and global fields of their transition
    ///
    /// - Given: A client with autoSessionTracking disabled
    /// - When:
    ///    - Fields change between startSession() and stopSession()
    /// - Then:
    ///    - The start carries the fields at the start and the stop those at the stop
    ///
    func testSessionEventsCarryFieldsAtTransition() async {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, autoSessionTracking: false)

        await client.setUserId("user-1")
        await client.addGlobalAttribute("key", value: "first")
        await client.addGlobalMetric("count", value: 1)
        await client.startSession()
        await client.setUserId("user-2")
        await client.addGlobalAttribute("key", value: "second")
        await client.addGlobalMetric("count", value: 2)
        await client.stopSession()
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
        XCTAssertEqual(events.map(\.userId), ["user-1", "user-2"])
        XCTAssertEqual(events.map { $0.attributes["key"] }, ["first", "second"])
        XCTAssertEqual(events.map { $0.metrics["count"] }, [1, 2])
    }

    /// Test that the launch session start carries the initial user ID and global fields
    ///
    /// - Given: A client created with initialUserId, initialGlobalAttributes and initialGlobalMetrics
    /// - When:
    ///    - An event is recorded and the client closes
    /// - Then:
    ///    - Every event, the launch start included, carries those values
    ///
    func testInitialFieldsAreOnLaunchStart() async throws {
        let sink = RecordingSink()
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS"),
            initialUserId: "user-1",
            initialGlobalAttributes: ["key": "value"],
            initialGlobalMetrics: ["count": 1],
            sink: sink
        )

        _ = try await client.record("a")
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "a", "_session.stop"])
        XCTAssertEqual(events.map(\.userId), ["user-1", "user-1", "user-1"])
        XCTAssertEqual(events.map { $0.attributes["key"] }, ["value", "value", "value"])
        XCTAssertEqual(events.map { $0.metrics["count"] }, [1, 1, 1])
    }

    /// Test that the initial fields can be changed afterwards
    ///
    /// - Given: A client created with an initial user ID and global attribute
    /// - When:
    ///    - Both are cleared and an event is recorded
    /// - Then:
    ///    - The event carries neither
    ///
    func testInitialFieldsCanBeCleared() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            initialUserId: "user-1",
            initialGlobalAttributes: ["key": "value"]
        )

        await client.setUserId(nil)
        await client.removeGlobalAttribute("key")
        let event = try await client.record("a")

        XCTAssertNil(event.userId)
        XCTAssertNil(event.attributes["key"])

        await client.close()
    }

    /// Test that a client created while the app is in the background starts paused
    ///
    /// - Given: The app is in the background
    /// - When:
    ///    - A client with autoSessionTracking is created
    /// - Then:
    ///    - Its launch session is paused
    ///
    func testClientCreatedInBackgroundStartsPaused() async throws {
        let original = ActivityTracker.isAppInBackground
        ActivityTracker.isAppInBackground = { true }
        defer { ActivityTracker.isAppInBackground = original }
        let client = makeClient(sink: RecordingSink())

        try await waitUntil { await client.sessionState == .paused }

        await client.close()
    }

    /// Test that a launch session started in the background times out
    ///
    /// - Given: The app is in the background
    /// - When:
    ///    - A client with a short timeout is created, and the app comes to the foreground later
    /// - Then:
    ///    - The launch session stops on its own, and the foreground starts a new session
    ///
    func testClientCreatedInBackgroundTimesOut() async throws {
        let original = ActivityTracker.isAppInBackground
        ActivityTracker.isAppInBackground = { true }
        defer { ActivityTracker.isAppInBackground = original }
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: 0.05)

        try await waitUntil { await sink.events.count == 2 }
        postForegroundNotification()
        try await waitUntil { await sink.events.count == 3 }
        await client.close()

        let events = await sink.events
        XCTAssertEqual(
            events.map(\.eventType),
            ["_session.start", "_session.stop", "_session.start", "_session.stop"]
        )
        XCTAssertEqual(Set(events.map(\.session.id)).count, 2)
        assertSessionOrder(events)
    }

    /// Test that an infinite session timeout does not crash when the app backgrounds
    ///
    /// - Given: A client with a session timeout of infinity
    /// - When:
    ///    - The app goes to the background and comes back
    /// - Then:
    ///    - The session stays paused, then resumes
    ///
    func testInfiniteTimeoutInBackgroundDoesNotCrash() async throws {
        try await assertPausedSessionNeverTimesOut(sessionTimeout: .infinity)
    }

    /// Test that a NaN session timeout does not crash when the app backgrounds
    ///
    /// - Given: A client with a session timeout of NaN
    /// - When:
    ///    - The app goes to the background and comes back
    /// - Then:
    ///    - The session stays paused, then resumes
    ///
    func testNaNTimeoutInBackgroundDoesNotCrash() async throws {
        try await assertPausedSessionNeverTimesOut(sessionTimeout: .nan)
    }

    /// Test that a negative session timeout does not crash when the app backgrounds
    ///
    /// - Given: A client with a negative session timeout
    /// - When:
    ///    - The app goes to the background
    /// - Then:
    ///    - The session stops right away
    ///
    func testNegativeTimeoutInBackgroundDoesNotCrash() async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: -1)

        postBackgroundNotification()
        try await waitUntil { await client.sessionState == .stopped }
        await client.close()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
    }

    /// Test that stopSession() returns once the sink has the stop
    ///
    /// - Given: A client whose sink takes a while per send
    /// - When:
    ///    - stopSession() is called
    /// - Then:
    ///    - The stop is in the sink when it returns
    ///
    func testStopSessionReturnsAfterStopIsSent() async {
        let sink = SlowSink()
        let client = makeClient(sink: sink)

        await client.stopSession()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
        await client.close()
    }

    /// Test that startSession() returns once the sink has the restart
    ///
    /// - Given: A client with a running session whose sink takes a while per send
    /// - When:
    ///    - startSession() is called
    /// - Then:
    ///    - The old session's stop and the new session's start are in the sink when it returns
    ///
    func testStartSessionReturnsAfterRestartIsSent() async {
        let sink = SlowSink()
        let client = makeClient(sink: sink)

        await client.startSession()

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop", "_session.start"])
        await client.close()
    }

    /// Test that stopSession() with no running session returns without waiting for the sink
    ///
    /// - Given: A stopped session whose start and stop are still held by the sink
    /// - When:
    ///    - stopSession() is called again
    /// - Then:
    ///    - It returns while the sends are still held
    ///
    func testStopSessionWithoutSessionReturnsPromptly() async throws {
        let sink = GatedSink()
        let client = makeClient(sink: sink)
        await sink.waitForSends(1)
        let stopping = Task { await client.stopSession() }
        try await waitUntil { await client.sessionState == .stopped }
        let returned = Flag()

        let noOp = Task {
            await client.stopSession()
            returned.set()
        }
        try await waitUntil { returned.isSet }

        await sink.releaseAll()
        await stopping.value
        await noOp.value
        await client.close()
    }

    /// Test that stopSession() does not return while the sink holds the stop
    ///
    /// - Given: A client whose sink holds each send until released
    /// - When:
    ///    - stopSession() is called and the stop is held
    /// - Then:
    ///    - It returns only after the stop is released
    ///
    func testStopSessionWaitsWhileStopIsHeld() async throws {
        let sink = GatedSink()
        let client = makeClient(sink: sink)
        await sink.release()
        let returned = Flag()

        let stopping = Task {
            await client.stopSession()
            returned.set()
        }
        await sink.waitForSends(2)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(returned.isSet)
        await sink.release()
        await stopping.value

        XCTAssertTrue(returned.isSet)
        let delivered = await sink.delivered
        XCTAssertEqual(delivered.map(\.eventType), ["_session.start", "_session.stop"])
        await sink.releaseAll()
        await client.close()
    }

    /// Test that startSession() does not return while the sink holds the restart
    ///
    /// - Given: A client with a running session whose sink holds each send until released
    /// - When:
    ///    - startSession() is called and the old stop, then the new start, are held
    /// - Then:
    ///    - It returns only after the new start is released
    ///
    func testStartSessionWaitsWhileRestartIsHeld() async throws {
        let sink = GatedSink()
        let client = makeClient(sink: sink)
        await sink.release()
        let returned = Flag()

        let starting = Task {
            await client.startSession()
            returned.set()
        }
        await sink.waitForSends(2)
        await sink.release()
        await sink.waitForSends(3)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(returned.isSet)
        await sink.release()
        await starting.value

        XCTAssertTrue(returned.isSet)
        let delivered = await sink.delivered
        XCTAssertEqual(delivered.map(\.eventType), ["_session.start", "_session.stop", "_session.start"])
        await sink.releaseAll()
        await client.close()
    }

    /// Test that a client released without close() sends its session's stop
    ///
    /// - Given: A client with a running session and a recorded event
    /// - When:
    ///    - The client is released without close()
    /// - Then:
    ///    - The sink receives the session's stop
    ///
    func testReleasedClientSendsStop() async throws {
        let sink = RecordingSink()
        var client: AmplifyEventEnrichmentClient? = makeClient(sink: sink)
        _ = try await client?.record("a")
        weak var released: AmplifyEventEnrichmentClient?
        released = client

        client = nil
        XCTAssertNil(released)
        try await waitUntil { await sink.events.count == 3 }

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "a", "_session.stop"])
        assertSessionOrder(events)
    }

    /// Test that a client released without close() stops a manually started session
    ///
    /// - Given: A client without autoSessionTracking and a session started by startSession()
    /// - When:
    ///    - The client is released without close()
    /// - Then:
    ///    - The sink receives the session's stop
    ///
    func testReleasedClientStopsManualSession() async throws {
        let sink = RecordingSink()
        var client: AmplifyEventEnrichmentClient? = makeClient(sink: sink, autoSessionTracking: false)
        await client?.startSession()

        client = nil
        try await waitUntil { await sink.events.count == 2 }

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
    }

    /// Test that releasing a closed client does not send a second stop
    ///
    /// - Given: A closed client
    /// - When:
    ///    - The client is released
    /// - Then:
    ///    - The sink has only the one stop from close()
    ///
    func testReleasedClosedClientSendsOneStop() async throws {
        let sink = RecordingSink()
        var client: AmplifyEventEnrichmentClient? = makeClient(sink: sink)
        await client?.close()

        client = nil
        try await Task.sleep(nanoseconds: 100_000_000)

        let events = await sink.events
        XCTAssertEqual(events.map(\.eventType), ["_session.start", "_session.stop"])
    }

    // MARK: - Helpers

    /// Backgrounds the app for longer than a short timeout would allow, then
    /// brings it back, and checks the session never timed out.
    private func assertPausedSessionNeverTimesOut(
        sessionTimeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let sink = RecordingSink()
        let client = makeClient(sink: sink, sessionTimeout: sessionTimeout)
        let launch = try await client.record("a")

        postBackgroundNotification()
        try await waitUntil { await client.sessionState == .paused }
        try await Task.sleep(nanoseconds: 100_000_000)
        let pausedState = await client.sessionState
        postForegroundNotification()
        try await waitUntil { await client.sessionState == .active }
        let resumed = try await client.record("b")
        await client.close()

        XCTAssertEqual(pausedState, .paused, file: file, line: line)
        XCTAssertEqual(resumed.session.id, launch.session.id, file: file, line: line)
        let events = await sink.events
        XCTAssertEqual(
            events.map(\.eventType),
            ["_session.start", "a", "b", "_session.stop"],
            file: file,
            line: line
        )
    }

    /// Polls `condition` until it holds, failing the test after `timeout` seconds.
    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while await !condition() {
            guard Date() < deadline else {
                XCTFail("Condition not met within \(timeout) s", file: file, line: line)
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func makeClient(
        sink: any EventSink,
        autoSessionTracking: Bool = true,
        sessionTimeout: TimeInterval = 5.0,
        emitSessionEvents: Bool = true
    ) -> AmplifyEventEnrichmentClient {
        AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS"),
            options: EventEnrichmentClientOptions(
                autoSessionTracking: autoSessionTracking,
                sessionTimeout: sessionTimeout,
                emitSessionEvents: emitSessionEvents
            ),
            sink: sink
        )
    }

    /// Asserts that boundaries alternate start and stop, starting with a start and
    /// ending with a stop, and that every record belongs to the open session.
    private func assertSessionOrder(
        _ events: [EnrichedEvent],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var openSessionId: String?
        for (index, event) in events.enumerated() {
            switch event.eventType {
            case "_session.start":
                XCTAssertNil(openSessionId, "start while a session is open at \(index)", file: file, line: line)
                openSessionId = event.session.id
            case "_session.stop":
                XCTAssertEqual(event.session.id, openSessionId, "stop of another session at \(index)", file: file, line: line)
                XCTAssertNotNil(event.session.stopTimestamp, "stop without timestamp at \(index)", file: file, line: line)
                openSessionId = nil
            default:
                XCTAssertEqual(event.session.id, openSessionId, "record outside its session at \(index)", file: file, line: line)
            }
        }
        XCTAssertNil(openSessionId, "no final stop", file: file, line: line)
    }

    private func postBackgroundNotification() {
        #if canImport(WatchKit)
        NotificationCenter.default.post(name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
        #elseif canImport(UIKit)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        #elseif canImport(AppKit)
        NotificationCenter.default.post(name: NSApplication.didHideNotification, object: nil)
        #endif
    }

    private func postForegroundNotification() {
        #if canImport(WatchKit)
        NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
        #elseif canImport(UIKit)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif canImport(AppKit)
        NotificationCenter.default.post(name: NSApplication.willUnhideNotification, object: nil)
        #endif
    }
}

/// Records every event in arrival order and the most sends ever in flight at once.
private actor RecordingSink: EventSink {
    private(set) var events: [EnrichedEvent] = []
    private(set) var maxInFlight = 0
    private var inFlight = 0
    private let delay: Bool

    init(delay: Bool = false) {
        self.delay = delay
    }

    func send(_ event: EnrichedEvent) async {
        inFlight += 1
        maxInFlight = max(maxInFlight, inFlight)
        if delay {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 0 ... 2_000_000))
        }
        events.append(event)
        inFlight -= 1
    }
}

/// Takes a fixed 20 ms per send, so a caller that does not wait for its send returns first.
private actor SlowSink: EventSink {
    private(set) var events: [EnrichedEvent] = []

    func send(_ event: EnrichedEvent) async {
        try? await Task.sleep(nanoseconds: 20_000_000)
        events.append(event)
    }
}

/// Holds each send until the test releases it.
private actor GatedSink: EventSink {
    private(set) var delivered: [EnrichedEvent] = []
    private var started = 0
    private var releases = 0
    private var held: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var open = false

    func send(_ event: EnrichedEvent) async {
        started += 1
        resumeStartWaiters()
        if !open, releases == 0 {
            await withCheckedContinuation { held.append($0) }
        } else if releases > 0 {
            releases -= 1
        }
        delivered.append(event)
    }

    /// Waits until `count` sends have started.
    func waitForSends(_ count: Int) async {
        if started >= count { return }
        await withCheckedContinuation { startWaiters.append((count, $0)) }
    }

    /// Lets the oldest held send finish, or the next one through if none is held.
    func release() {
        if held.isEmpty {
            releases += 1
        } else {
            held.removeFirst().resume()
        }
    }

    /// Lets every held and future send through.
    func releaseAll() {
        open = true
        held.forEach { $0.resume() }
        held.removeAll()
    }

    private func resumeStartWaiters() {
        let ready = startWaiters.filter { $0.count <= started }
        startWaiters.removeAll { $0.count <= started }
        ready.forEach { $0.continuation.resume() }
    }
}

/// A flag a test can read without suspending.
private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }
}
