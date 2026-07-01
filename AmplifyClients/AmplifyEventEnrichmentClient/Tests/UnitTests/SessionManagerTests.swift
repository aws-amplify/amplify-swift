//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import XCTest

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class SessionManagerTests: XCTestCase {

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

    /// Test that short appId is padded in session ID
    ///
    /// - Given: A session manager with a short appId (< 8 chars)
    /// - When:
    ///    - A session is started
    /// - Then:
    ///    - The session ID prefix is padded to 8 chars
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
        XCTAssertTrue(session!.id.hasPrefix("_____app-"))
    }
}
