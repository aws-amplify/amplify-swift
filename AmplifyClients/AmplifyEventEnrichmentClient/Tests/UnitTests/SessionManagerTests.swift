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

    /// Test that resuming after an explicit stop does not start a new session
    ///
    /// - Given: A session manager whose session was stopped with stopSession()
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - The manager stays stopped on the session that was stopped
    ///
    func testHandleAppResumedFromStopped() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        await manager.stopSession()
        let stopped = await manager.session
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .stopped)
        XCTAssertEqual(session?.id, stopped?.id)
        XCTAssertNotNil(session?.stopTimestamp)
    }

    /// Test that resuming after a timeout stop starts a new session
    ///
    /// - Given: A session manager whose paused session timed out
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - A new session starts, since only an explicit stop is sticky
    ///
    func testHandleAppResumedAfterTimeoutStartsNewSession() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        let first = await manager.session
        await manager.handleAppPaused()
        await manager.onTimeoutExpired(pauseGeneration: 1)
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertNotEqual(session?.id, first?.id)
    }

    /// Test that startSession() after an explicit stop re-enables resume
    ///
    /// - Given: A session manager that was stopped and then started again
    /// - When:
    ///    - The app pauses and resumes
    /// - Then:
    ///    - The session is active
    ///
    func testStartSessionAfterStopReenablesResume() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        await manager.stopSession()
        await manager.startSession()
        await manager.handleAppPaused()
        await manager.handleAppResumed()

        let state = await manager.state
        XCTAssertEqual(state, .active)
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

        // The paused -> stopped transition is driven by an internal timer (`sessionTimeout`).
        // Poll for the terminal state instead of asserting once after a fixed delay, which races
        // the timer's Task scheduling on a loaded CI runner and intermittently still reads `.paused`.
        var state = await manager.state
        let deadline = Date().addingTimeInterval(2)
        while state != .stopped, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000) // 20ms
            state = await manager.state
        }
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

    /// Test that a timeout firing after a resume does not stop the resumed session
    ///
    /// - Given: A session manager that paused and resumed
    /// - When:
    ///    - The timeout for that pause is delivered late
    /// - Then:
    ///    - The session stays active and unstopped
    ///
    func testStaleTimeoutAfterResumeDoesNotStopSession() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        let first = await manager.session
        await manager.handleAppPaused()
        await manager.handleAppResumed()
        await manager.onTimeoutExpired(pauseGeneration: 1)

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertEqual(session?.id, first?.id)
        XCTAssertNil(session?.stopTimestamp)
    }

    /// Test that a timeout from an earlier pause does not end a later pause
    ///
    /// - Given: A session manager that paused, resumed and paused again
    /// - When:
    ///    - The timeout for the first pause is delivered late
    /// - Then:
    ///    - The second pause is unaffected
    ///
    func testStaleTimeoutFromEarlierPauseDoesNotEndLaterPause() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        await manager.handleAppPaused()
        await manager.handleAppResumed()
        await manager.handleAppPaused()
        await manager.onTimeoutExpired(pauseGeneration: 1)

        let state = await manager.state
        XCTAssertEqual(state, .paused)
    }

    /// Test that a timeout from an earlier pause leaves the later session resumable
    ///
    /// - Given: A session manager that paused, resumed and paused again
    /// - When:
    ///    - The timeout for the first pause is delivered late and the app resumes
    /// - Then:
    ///    - The original session is active and was never stopped
    ///
    func testStaleTimeoutFromEarlierPauseKeepsSessionOnResume() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.startSession()
        let first = await manager.session
        await manager.handleAppPaused()
        await manager.handleAppResumed()
        await manager.handleAppPaused()
        await manager.onTimeoutExpired(pauseGeneration: 1)
        await manager.handleAppResumed()

        let session = await manager.session
        XCTAssertEqual(session?.id, first?.id)
        XCTAssertNil(session?.stopTimestamp)
    }

    /// Test that a resume landing next to the timeout is never undone by it
    ///
    /// - Given: A session manager with a timeout of a few milliseconds
    /// - When:
    ///    - The app resumes right around the moment the timeout fires
    /// - Then:
    ///    - The session is active afterwards, every time
    ///
    func testResumeNearTimeoutIsNeverUndone() async throws {
        for iteration in 0 ..< 200 {
            let timeout = 0.002 + Double(iteration % 8) * 0.0005
            let manager = SessionManager(
                appId: "test-app",
                sessionTimeout: timeout,
                generateId: { UUID().uuidString }
            )
            await manager.startSession()
            await manager.handleAppPaused()
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            await manager.handleAppResumed()
            try await Task.sleep(nanoseconds: 3_000_000)
            let state = await manager.state
            XCTAssertEqual(state, .active, "iteration \(iteration)")
        }
    }

    /// Test that stopping twice keeps the first stop
    ///
    /// - Given: A session manager whose session was stopped
    /// - When:
    ///    - stopSession() is called again later
    /// - Then:
    ///    - The stop timestamp and duration are unchanged
    ///
    func testStopSessionTwiceKeepsFirstStop() async throws {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )
        let start = clock.now

        await manager.startSession()
        clock.advance(by: 1)
        await manager.stopSession()
        clock.advance(by: 5)
        await manager.stopSession()

        let currentSession = await manager.session
        let session = try XCTUnwrap(currentSession)
        XCTAssertEqual(session.stopTimestamp, start.addingTimeInterval(1))
        XCTAssertEqual(session.duration, 1_000)
    }

    /// Test that stopping a timed-out session keeps the pause time
    ///
    /// - Given: A session manager whose paused session timed out
    /// - When:
    ///    - stopSession() is called later
    /// - Then:
    ///    - The stop timestamp is still the pause time
    ///
    func testStopSessionAfterTimeoutKeepsPauseTime() async throws {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )
        let start = clock.now

        await manager.startSession()
        clock.advance(by: 2)
        await manager.handleAppPaused()
        clock.advance(by: 10)
        await manager.onTimeoutExpired(pauseGeneration: 1)
        clock.advance(by: 3)
        await manager.stopSession()

        let currentSession = await manager.session
        let session = try XCTUnwrap(currentSession)
        XCTAssertEqual(session.stopTimestamp, start.addingTimeInterval(2))
        XCTAssertEqual(session.duration, 2_000)
    }

    /// Test that an explicit stop while paused is stamped at the pause time
    ///
    /// - Given: A session manager whose session is paused
    /// - When:
    ///    - stopSession() is called later, within the timeout
    /// - Then:
    ///    - The stop timestamp is the pause time
    ///
    func testStopSessionWhilePausedUsesPauseTime() async throws {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )
        let start = clock.now

        await manager.startSession()
        clock.advance(by: 2)
        await manager.handleAppPaused()
        clock.advance(by: 1)
        await manager.stopSession()

        let currentSession = await manager.session
        let session = try XCTUnwrap(currentSession)
        XCTAssertEqual(session.stopTimestamp, start.addingTimeInterval(2))
    }

    /// Test that resuming after the timeout starts a new session even if the timer never fired
    ///
    /// - Given: A paused session whose timeout has elapsed by the clock but not by the timer
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - A new active session replaces the old one
    ///
    func testResumeAfterExpiredPauseStartsNewSession() async {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )

        await manager.startSession()
        let first = await manager.session
        await manager.handleAppPaused()
        clock.advance(by: 6)
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertNotEqual(session?.id, first?.id)
    }

    /// Test that the session started after an expired pause begins at the resume
    ///
    /// - Given: A paused session whose timeout has elapsed by the clock but not by the timer
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - The current session starts at the resume time and is not stopped
    ///
    func testResumeAfterExpiredPauseStartsAtResumeTime() async throws {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )

        await manager.startSession()
        await manager.handleAppPaused()
        clock.advance(by: 6)
        let resumeTime = clock.now
        await manager.handleAppResumed()

        let currentSession = await manager.session
        let session = try XCTUnwrap(currentSession)
        XCTAssertEqual(session.startTimestamp, resumeTime)
        XCTAssertNil(session.stopTimestamp)
    }

    /// Test that resuming within the timeout keeps the session
    ///
    /// - Given: A paused session whose timeout has not elapsed by the clock
    /// - When:
    ///    - handleAppResumed() is called
    /// - Then:
    ///    - The same session is active
    ///
    func testResumeWithinTimeoutKeepsSession() async {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )

        await manager.startSession()
        let first = await manager.session
        await manager.handleAppPaused()
        clock.advance(by: 4)
        await manager.handleAppResumed()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertEqual(session?.id, first?.id)
    }

    /// Test that dispose() stops the session and ignores later session calls
    ///
    /// - Given: A disposed session manager
    /// - When:
    ///    - startSession() and stopSession() are called
    /// - Then:
    ///    - The manager stays stopped and the final stop is unchanged
    ///
    func testDisposeIgnoresLaterSessionCalls() async throws {
        let clock = TestClock()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString },
            now: { clock.now }
        )

        await manager.startSession()
        await manager.dispose()
        let currentDisposed = await manager.session
        let disposed = try XCTUnwrap(currentDisposed)
        clock.advance(by: 1)
        await manager.startSession()
        await manager.stopSession()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .stopped)
        XCTAssertEqual(session?.id, disposed.id)
        XCTAssertEqual(session?.stopTimestamp, disposed.stopTimestamp)
    }

    /// Test that dispose() ignores later lifecycle calls
    ///
    /// - Given: A disposed session manager that had never stopped explicitly
    /// - When:
    ///    - handleAppResumed() and handleAppPaused() are called
    /// - Then:
    ///    - No session is started
    ///
    func testDisposeIgnoresLaterLifecycleCalls() async {
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 5.0,
            generateId: { UUID().uuidString }
        )

        await manager.dispose()
        await manager.handleAppResumed()
        await manager.handleAppPaused()

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .stopped)
        XCTAssertNil(session)
    }

    /// Test that a manager created with startingSession reports the start
    ///
    /// - Given: A session manager created with startingSession = true
    /// - When:
    ///    - It is initialized
    /// - Then:
    ///    - It is active and has reported one start for its session
    ///
    func testStartingSessionReportsStart() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            startingSession: true,
            onBoundary: recorder.record
        )

        let state = await manager.state
        let session = await manager.session
        XCTAssertEqual(state, .active)
        XCTAssertEqual(recorder.boundaries, [.start])
        XCTAssertEqual(recorder.sessionIds, [session?.id])
    }

    /// Test that startSession() while active ends the session before starting a new one
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - startSession() is called again
    /// - Then:
    ///    - It reports a stop for the old session, then a start for a new one
    ///
    func testStartSessionWhileActiveReportsStopThenStart() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            onBoundary: recorder.record
        )

        await manager.startSession()
        let first = await manager.session
        await manager.startSession()
        let second = await manager.session

        XCTAssertEqual(recorder.boundaries, [.start, .stop, .start])
        XCTAssertEqual(recorder.sessionIds, [first?.id, first?.id, second?.id])
        XCTAssertNotEqual(first?.id, second?.id)
        XCTAssertNotNil(recorder.sessions[1].stopTimestamp)
        XCTAssertNotNil(recorder.sessions[1].duration)
    }

    /// Test that a session is reported stopped once
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - stopSession() is called twice and then dispose()
    /// - Then:
    ///    - One stop is reported
    ///
    func testStopIsReportedOnce() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            onBoundary: recorder.record
        )

        await manager.startSession()
        await manager.stopSession()
        await manager.stopSession()
        await manager.dispose()

        XCTAssertEqual(recorder.boundaries, [.start, .stop])
    }

    /// Test that a pause and resume within the timeout reports nothing
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - The app pauses and resumes within the timeout
    /// - Then:
    ///    - No boundary is reported beyond the start
    ///
    func testPauseAndResumeWithinTimeoutReportsNothing() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            onBoundary: recorder.record
        )

        await manager.startSession()
        await manager.handleAppPaused()
        await manager.handleAppResumed()

        XCTAssertEqual(recorder.boundaries, [.start])
    }

    /// Test that a timeout reports a stop stamped at the pause, and the resume only a start
    ///
    /// - Given: A paused session whose timer fired
    /// - When:
    ///    - The app resumes
    /// - Then:
    ///    - The stop was reported with the pause time, and the resume reports only a start
    ///
    func testTimeoutReportsStopAndResumeReportsStart() async {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.startSession()
        clock.advance(by: 2)
        let pauseTime = clock.now
        await manager.handleAppPaused()
        clock.advance(by: 6)
        await manager.onTimeoutExpired(pauseGeneration: 1)
        XCTAssertEqual(recorder.boundaries, [.start, .stop])
        await manager.handleAppResumed()

        XCTAssertEqual(recorder.boundaries, [.start, .stop, .start])
        XCTAssertEqual(recorder.sessions[1].stopTimestamp, pauseTime)
        XCTAssertEqual(recorder.sessions[1].duration, 2_000)
    }

    /// Test that resuming after an expired pause whose timer never fired reports stop then start
    ///
    /// - Given: A paused session whose timeout elapsed by the clock but not by the timer
    /// - When:
    ///    - The app resumes
    /// - Then:
    ///    - A stop stamped at the pause time is reported, then a start
    ///
    func testExpiredResumeReportsStopThenStart() async {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.startSession()
        let pauseTime = clock.now
        await manager.handleAppPaused()
        clock.advance(by: 6)
        await manager.handleAppResumed()

        XCTAssertEqual(recorder.boundaries, [.start, .stop, .start])
        XCTAssertEqual(recorder.sessions[1].stopTimestamp, pauseTime)
    }

    /// Test that the recording session starts a session first when there is none
    ///
    /// - Given: A stopped session manager
    /// - When:
    ///    - withRecordingSession runs a body
    /// - Then:
    ///    - The start is reported before the body runs, and the body gets that session
    ///
    func testRecordingSessionStartsSessionBeforeBody() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            onBoundary: recorder.record
        )

        let id = await manager.withRecordingSession { session in
            recorder.note()
            return session.id
        }

        XCTAssertEqual(recorder.log, ["start", "body"])
        XCTAssertEqual(recorder.sessionIds, [id])
    }

    /// Test that the recording session replaces a session paused past its timeout
    ///
    /// - Given: A paused session whose timeout elapsed by the clock but not by the timer
    /// - When:
    ///    - withRecordingSession runs a body
    /// - Then:
    ///    - Stop and start are reported before the body, which gets the new session
    ///
    func testRecordingSessionReplacesExpiredPause() async {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.startSession()
        await manager.handleAppPaused()
        clock.advance(by: 6)
        let id = await manager.withRecordingSession { session in
            recorder.note()
            return session.id
        }

        XCTAssertEqual(recorder.log, ["start", "stop", "start", "body"])
        XCTAssertEqual(recorder.sessionIds.last, id)
    }

    /// Test that a session started by a record while backgrounded starts paused
    ///
    /// - Given: A stopped session manager that has seen the app go to background
    /// - When:
    ///    - withRecordingSession runs a body
    /// - Then:
    ///    - The new session is paused, and resuming within the timeout keeps it
    ///
    func testRecordingSessionStartedInBackgroundIsPaused() async {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.handleAppPaused()
        let id = await manager.withRecordingSession { $0.id }
        let state = await manager.state

        XCTAssertEqual(state, .paused)
        clock.advance(by: 1)
        await manager.handleAppResumed()
        let resumed = await manager.state
        let session = await manager.session
        XCTAssertEqual(resumed, .active)
        XCTAssertEqual(session?.id, id)
        XCTAssertEqual(recorder.boundaries, [.start])
    }

    /// Test that a session started while backgrounded times out
    ///
    /// - Given: A session manager with a short timeout that has seen the app go to background
    /// - When:
    ///    - startSession() is called and the timeout elapses
    /// - Then:
    ///    - The session is stopped, stamped at its start
    ///
    func testSessionStartedInBackgroundTimesOut() async throws {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            sessionTimeout: 0.05,
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.handleAppPaused()
        await manager.startSession()
        let state = await manager.state
        XCTAssertEqual(state, .paused)

        try await Task.sleep(nanoseconds: 300_000_000)

        let stopped = await manager.state
        XCTAssertEqual(stopped, .stopped)
        XCTAssertEqual(recorder.boundaries, [.start, .stop])
        XCTAssertEqual(recorder.sessions.last?.stopTimestamp, recorder.sessions.first?.startTimestamp)
    }

    /// Test that a session replacing an expired pause stays paused in the background
    ///
    /// - Given: A paused session whose timeout elapsed by the clock, app still backgrounded
    /// - When:
    ///    - withRecordingSession runs a body
    /// - Then:
    ///    - Stop and start are reported and the new session is paused
    ///
    func testRecordingSessionReplacingExpiredPauseStaysPaused() async {
        let clock = TestClock()
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            now: { clock.now },
            onBoundary: recorder.record
        )

        await manager.startSession()
        await manager.handleAppPaused()
        clock.advance(by: 6)
        _ = await manager.withRecordingSession { $0.id }
        let state = await manager.state

        XCTAssertEqual(recorder.boundaries, [.start, .stop, .start])
        XCTAssertEqual(state, .paused)
    }

    /// Test that returning to foreground with no session clears the background state
    ///
    /// - Given: An explicitly stopped session manager
    /// - When:
    ///    - The app goes to background and returns, then startSession() is called
    /// - Then:
    ///    - The new session is active
    ///
    func testForegroundWithoutSessionClearsBackground() async {
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString }
        )

        await manager.stopSession()
        await manager.handleAppPaused()
        await manager.handleAppResumed()
        await manager.startSession()

        let state = await manager.state
        XCTAssertEqual(state, .active)
    }

    /// Test that dispose() reports the final stop and nothing afterwards
    ///
    /// - Given: A session manager with an active session
    /// - When:
    ///    - dispose() runs, followed by session and lifecycle calls
    /// - Then:
    ///    - Only the final stop is reported after the start
    ///
    func testDisposeReportsFinalStopOnly() async {
        let recorder = BoundaryRecorder()
        let manager = SessionManager(
            appId: "test-app",
            generateId: { UUID().uuidString },
            onBoundary: recorder.record
        )

        await manager.startSession()
        await manager.dispose()
        await manager.startSession()
        await manager.handleAppResumed()
        let id = await manager.withRecordingSession { $0.id }

        XCTAssertNil(id)
        XCTAssertEqual(recorder.boundaries, [.start, .stop])
    }
}

/// A clock that only moves when a test advances it.
private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 1_700_000_000)

    var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock()
        current = current.addingTimeInterval(seconds)
        lock.unlock()
    }
}

/// Records reported boundaries, and body runs marked with `note()`, in order.
private final class BoundaryRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [(boundary: SessionBoundary?, session: Session?)] = []

    var record: @Sendable (SessionBoundary, Session) -> Void {
        { [self] boundary, session in
            lock.lock()
            entries.append((boundary, session))
            lock.unlock()
        }
    }

    func note() {
        lock.lock()
        entries.append((nil, nil))
        lock.unlock()
    }

    private var snapshot: [(boundary: SessionBoundary?, session: Session?)] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    var boundaries: [SessionBoundary] { snapshot.compactMap(\.boundary) }
    var sessions: [Session] { snapshot.compactMap(\.session) }
    var sessionIds: [String?] { sessions.map(\.id) }
    var log: [String] {
        snapshot.map { entry in
            switch entry.boundary {
            case .start: return "start"
            case .stop: return "stop"
            case nil: return "body"
            }
        }
    }
}
