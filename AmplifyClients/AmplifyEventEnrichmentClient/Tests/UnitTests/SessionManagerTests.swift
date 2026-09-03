//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class SessionManagerTests: XCTestCase, @unchecked Sendable {

    /// Test that starting a session transitions state to active
    ///
    /// - Given: A session manager in stopped state
    /// - When:
    ///    - startSession() is called
    /// - Then:
    ///    - State becomes active and session is non-nil
    ///
    func testStartSession() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertNotNil(session)
        XCTAssertTrue(session!.id.contains("test-app"))
    }

    /// Test that stopping a session records stop time and duration
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - stopSession() is called
    /// - Then:
    ///    - State becomes stopped and session has stopTimestamp and duration
    ///
    func testStopSession() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        await manager.stopSession()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .stopped)
        XCTAssertNotNil(session?.stopTimestamp)
        XCTAssertNotNil(session?.duration)
    }

    /// Test that pausing transitions to paused state
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - handleAppPaused() is called
    /// - Then:
    ///    - State becomes paused
    ///
    func testHandleAppPaused() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        await manager.handleAppPaused()

        let state = await manager.state
        XCTAssertEqual(state, .paused)
    }

    /// Test that resuming from paused returns to active with same session
    ///
    /// - Given: A session manager in paused state
    /// - When:
    ///    - handleAppResumed() is called before timeout
    /// - Then:
    ///    - State becomes active with the same session ID
    ///
    func testHandleAppResumedFromPaused() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        let originalSession = await manager.session

        await manager.handleAppPaused()
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertEqual(session?.id, originalSession?.id)
    }

    /// Test that resuming from stopped starts a new session
    ///
    /// - Given: A session manager in stopped state
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - A new session is started
    ///
    func testHandleAppResumedFromStopped() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        await manager.stopSession()
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertNotNil(session)
    }

    /// Test session timeout expires and stops session
    ///
    /// - Given: A session manager with a short timeout
    /// - When:
    ///    - handleAppPaused() is called and timeout elapses
    /// - Then:
    ///    - State becomes stopped
    ///
    func testSessionTimeoutExpires() async throws {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 0.1,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        await manager.handleAppPaused()

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let state = await manager.state
        XCTAssertEqual(state, .stopped)
    }

    /// Test that the session ID format includes appId prefix
    ///
    /// - Given: A session manager with a known appId
    /// - When:
    ///    - A session is started
    /// - Then:
    ///    - The session ID starts with the appId prefix (up to 8 chars)
    ///
    func testSessionIdFormat() async {
        let manager = SessionManager(
            appId: "myAppId1",
            sessionTimeout: 5.0,
            generateId: { "abcdefgh-1234" }
        )

        await manager.startSession()
        let session = await manager.session

        XCTAssertNotNil(session)
        XCTAssertTrue(session!.id.hasPrefix("myAppId1-"))
        XCTAssertTrue(session!.id.contains("abcdefgh"))
    }

    /// Test that the session ID uses the expected four-segment layout
    ///
    /// - Given: A session manager with an appId and unique ID longer than 8 chars
    /// - When:
    ///    - A session is started
    /// - Then:
    ///    - The ID is `<appId>-<uniqueId>-<yyyyMMdd>-<HHmmssSSS>` with both keys
    ///      truncated to 8 characters
    ///
    func testSessionIdLayout() async {
        let manager = SessionManager(
            appId: "myAppIdIsLong",
            sessionTimeout: 5.0,
            generateId: { "abcdefghijkl" }
        )

        await manager.startSession()
        let session = await manager.session

        let sessionId = try? XCTUnwrap(session?.id)
        let components = sessionId?.split(separator: "-")
        XCTAssertEqual(components?.count, 4)
        XCTAssertEqual(components?[0], "myAppIdI")
        XCTAssertEqual(components?[1], "abcdefgh")
        XCTAssertEqual(components?[2].count, 8)
        XCTAssertEqual(components?[3].count, 9)
        XCTAssertTrue(components?[2].allSatisfy(\.isNumber) ?? false)
        XCTAssertTrue(components?[3].allSatisfy(\.isNumber) ?? false)
    }

    /// Test that short appId is padded in session ID
    ///
    /// - Given: A session manager with a short appId (< 8 chars)
    /// - When:
    ///    - A session is started
    /// - Then:
    ///    - The session ID prefix is right-padded to 8 chars
    ///
    func testShortAppIdPaddedInSessionId() async {
        let manager = SessionManager(
            appId: "app",
            sessionTimeout: 5.0,
            generateId: { "abcdefgh-1234" }
        )

        await manager.startSession()
        let session = await manager.session

        XCTAssertNotNil(session)
        XCTAssertTrue(session!.id.hasPrefix("app_____-"))
    }

    /// Test that a short unique ID is padded in the session ID
    ///
    /// - Given: A session manager whose generateId returns fewer than 8 characters
    /// - When:
    ///    - A session is started
    /// - Then:
    ///    - The unique ID segment is right-padded to 8 chars
    ///
    func testShortUniqueIdPaddedInSessionId() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "abc" }
        )

        await manager.startSession()
        let session = await manager.session

        XCTAssertNotNil(session)
        XCTAssertTrue(session!.id.contains("-abc_____-"))
    }

    /// Test that a stopped session is not exposed as active
    ///
    /// - Given: A session manager whose session has been stopped
    /// - When:
    ///    - activeSession and session are read
    /// - Then:
    ///    - activeSession is nil while session still reports the stopped session
    ///
    func testActiveSessionIsNilAfterStop() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        let activeWhileRunning = await manager.activeSession
        XCTAssertNotNil(activeWhileRunning)

        await manager.stopSession()

        let activeAfterStop = await manager.activeSession
        let lastSession = await manager.session
        XCTAssertNil(activeAfterStop)
        XCTAssertNotNil(lastSession)
    }

    /// Test that a paused session is still considered active for attribution
    ///
    /// - Given: A session manager whose session is paused within the timeout
    /// - When:
    ///    - activeSession is read
    /// - Then:
    ///    - The paused session is returned, since it may still resume
    ///
    func testActiveSessionAvailableWhilePaused() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        await manager.handleAppPaused()

        let pausedSession = await manager.activeSession
        XCTAssertNotNil(pausedSession)
    }

    /// Test that a timed-out session stops at the pause time, not the expiry time
    ///
    /// - Given: A session manager with a short timeout that is paused
    /// - When:
    ///    - The timeout expires
    /// - Then:
    ///    - The stop timestamp is the pause time, so the duration excludes the
    ///      time spent backgrounded
    ///
    func testTimeoutExpiryUsesPauseTimeAsStopTime() async throws {
        let timeout: TimeInterval = 0.2
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: timeout,
            generateId: { "fixed-uuid" }
        )

        await manager.startSession()
        await manager.handleAppPaused()
        let pauseTime = Date()

        try await Task.sleep(nanoseconds: 500_000_000) // 500ms, well past the timeout

        let currentSession = await manager.session
        let state = await manager.state
        let session = try XCTUnwrap(currentSession)
        let stopTimestamp = try XCTUnwrap(session.stopTimestamp)
        let duration = try XCTUnwrap(session.duration)
        XCTAssertEqual(state, .stopped)
        // The stop time is the pause time, not pause + timeout.
        XCTAssertEqual(stopTimestamp.timeIntervalSince1970, pauseTime.timeIntervalSince1970, accuracy: 0.15)
        XCTAssertLessThan(duration, Int64(timeout * 1_000))
    }
}
