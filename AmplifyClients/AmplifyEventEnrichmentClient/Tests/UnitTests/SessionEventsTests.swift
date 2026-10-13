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
        XCTAssertEqual(events.filter { $0.eventType == "_session.start" }.count, 20)
        XCTAssertEqual(events.filter { $0.eventType == "_session.stop" }.count, 20)
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

    // MARK: - Helpers

    private func makeClient(
        sink: any EventSink,
        autoSessionTracking: Bool = true,
        sessionTimeout: TimeInterval = 5.0
    ) -> AmplifyEventEnrichmentClient {
        AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            deviceMetadata: DeviceMetadata(platform: "iOS"),
            options: EventEnrichmentClientOptions(
                autoSessionTracking: autoSessionTracking,
                sessionTimeout: sessionTimeout
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
