//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Streams are subscribed before anything is sent and buffer without limit, so each test can send,
/// finish, and then read every stream to its end. What a subscriber received is then a fixed list,
/// with no dependence on when its reader happened to run.
final class SessionEventStreamTests: XCTestCase {

    private static func collect<Event>(_ stream: AsyncStream<Event>) async -> [Event] {
        var received: [Event] = []
        for await event in stream {
            received.append(event)
        }
        return received
    }

    /// - Given: three subscribers on one session
    /// - When: a sequence of events is sent and the broadcaster is finished
    /// - Then:
    ///    - every subscriber received every event, in the order sent
    func testEverySubscriberReceivesEveryEventInOrder() async {
        let broadcaster = SessionEventStream<AuthEvent>()
        let streams = (0 ..< 3).map { _ in broadcaster.events() }
        let sent: [AuthEvent] = [.signedIn, .sessionExpired, .signedIn, .signedOut, .userDeleted]

        for event in sent {
            broadcaster.send(event)
        }
        broadcaster.finish()

        for stream in streams {
            let received = await Self.collect(stream)
            XCTAssertEqual(received, sent)
        }
    }

    /// Delivery is under one lock, so concurrent senders produce one order that every subscriber
    /// shares. Uses distinct integers so any reordering between subscribers is visible.
    ///
    /// - Given: two subscribers
    /// - When: 200 distinct events are sent from concurrent tasks
    /// - Then:
    ///    - both subscribers received all 200, in the same order as each other
    func testConcurrentSendsAreSeenInOneOrderByEverySubscriber() async {
        let broadcaster = SessionEventStream<Int>()
        let first = broadcaster.events()
        let second = broadcaster.events()

        await withTaskGroup(of: Void.self) { group in
            for value in 0 ..< 200 {
                group.addTask { broadcaster.send(value) }
            }
        }
        broadcaster.finish()

        let firstReceived = await Self.collect(first)
        let secondReceived = await Self.collect(second)
        XCTAssertEqual(firstReceived.count, 200)
        XCTAssertEqual(Set(firstReceived), Set(0 ..< 200))
        XCTAssertEqual(firstReceived, secondReceived)
    }

    /// Events are delivered from the point of subscription (design §8).
    ///
    /// - Given: an event sent before anyone subscribed
    /// - When: a subscriber attaches and a second event is sent
    /// - Then:
    ///    - the subscriber receives only the second event
    func testEventsSentBeforeSubscribingAreNotReplayed() async {
        let broadcaster = SessionEventStream<AuthEvent>()
        broadcaster.send(.signedIn)

        let stream = broadcaster.events()
        broadcaster.send(.signedOut)
        broadcaster.finish()

        let received = await Self.collect(stream)
        XCTAssertEqual(received, [.signedOut])
    }

    /// - Given: two subscribers, one of them read by a task
    /// - When:
    ///    - that task is cancelled after receiving an event, and another event is sent
    /// - Then:
    ///    - the cancelled subscriber is removed from the broadcaster and receives nothing more, and
    ///      the other subscriber still receives both events
    func testTerminatedSubscriberIsDropped() async {
        let broadcaster = SessionEventStream<AuthEvent>()
        let kept = broadcaster.events()
        let cancelled = broadcaster.events()
        XCTAssertEqual(broadcaster.subscriberCount, 2)

        let receivedOne = Gate(isOpen: true)
        let reader = Task {
            var received: [AuthEvent] = []
            for await event in cancelled {
                received.append(event)
                await receivedOne.pass()
            }
            return received
        }

        broadcaster.send(.signedIn)
        await receivedOne.waitForArrivals(1)
        reader.cancel()
        await waitUntil("the cancelled subscriber is removed") { broadcaster.subscriberCount == 1 }

        broadcaster.send(.signedOut)
        let cancelledReceived = await reader.value
        broadcaster.finish()
        let keptReceived = await Self.collect(kept)

        XCTAssertEqual(cancelledReceived, [.signedIn])
        XCTAssertEqual(keptReceived, [.signedIn, .signedOut])
        XCTAssertEqual(broadcaster.subscriberCount, 0)
    }

    /// - Given: two subscribers
    /// - When: the broadcaster is finished, then subscribed to and sent to again
    /// - Then:
    ///    - both streams end, the late subscriber's stream is already finished, the later send is
    ///      ignored, and nothing stays registered
    func testFinishEndsEveryStreamAndIsFinal() async {
        let broadcaster = SessionEventStream<AuthEvent>()
        let first = broadcaster.events()
        let second = broadcaster.events()

        broadcaster.finish()
        let late = broadcaster.events()
        broadcaster.send(.signedIn)

        let firstReceived = await Self.collect(first)
        let secondReceived = await Self.collect(second)
        let lateReceived = await Self.collect(late)
        XCTAssertEqual(firstReceived, [])
        XCTAssertEqual(secondReceived, [])
        XCTAssertEqual(lateReceived, [])
        XCTAssertEqual(broadcaster.subscriberCount, 0)
    }

    /// Dropping the last reference must end the streams, or a `for await` loop over a released
    /// session would hang. Also shows that a registered stream does not keep the broadcaster alive.
    ///
    /// - Given: a subscriber on a broadcaster that has sent one event
    /// - When: the only reference to the broadcaster is released
    /// - Then:
    ///    - the broadcaster is deallocated, and the stream delivers the event it buffered and ends
    func testReleasingTheBroadcasterEndsItsStreams() async {
        weak var released: SessionEventStream<AuthEvent>?
        let stream: AsyncStream<AuthEvent>
        do {
            let broadcaster = SessionEventStream<AuthEvent>()
            released = broadcaster
            stream = broadcaster.events()
            broadcaster.send(.signedIn)
        }

        XCTAssertNil(released, "A subscriber must not keep the broadcaster alive")
        let received = await Self.collect(stream)
        XCTAssertEqual(received, [.signedIn])
    }

    /// One session's events never reach, or are suppressed by, another session's stream.
    ///
    /// - Given: two broadcasters, standing for two sessions, each with a subscriber
    /// - When:
    ///    - each sends different events, and one is finished while the other keeps sending
    /// - Then:
    ///    - each subscriber received only its own session's events, and finishing one session did
    ///      not end the other
    func testTwoBroadcastersAreIndependent() async {
        let work = SessionEventStream<AuthEvent>()
        let home = SessionEventStream<AuthEvent>()
        let workStream = work.events()
        let homeStream = home.events()

        work.send(.signedIn)
        home.send(.signedIn)
        home.send(.signedOut)
        work.finish()
        home.send(.userDeleted)
        home.finish()

        let workReceived = await Self.collect(workStream)
        let homeReceived = await Self.collect(homeStream)
        XCTAssertEqual(workReceived, [.signedIn])
        XCTAssertEqual(homeReceived, [.signedIn, .signedOut, .userDeleted])
    }
}
