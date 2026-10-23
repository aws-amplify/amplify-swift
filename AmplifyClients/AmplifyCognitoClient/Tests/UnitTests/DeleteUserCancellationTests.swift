//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `deleteUser()` and the calling task's cancellation: once Cognito is asked, the deletion and its clean-up run to
/// their end; before, a cancelled caller deletes nothing.
final class DeleteUserCancellationTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// The `userNotFound` clean-up, the global sign-out and the row's removal, is part of the deletion, so the
    /// caller's cancellation cannot keep the deleted user's row.
    ///
    /// - Given: a signed-in session whose deletion is held in the engine, then answered `userNotFound`
    /// - When: the caller is cancelled while it is held, and the deletion is let go
    /// - Then:
    ///    - it throws `service(.userNotFound)`; the session was signed out globally, its row purged, and its state
    ///      is signed out
    func testACancelledCallerStillSignsOutAUserCognitoNoLongerKnows() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.scriptDeleteUser { _ in
            await latch.pass()
            throw SessionEngineError.service(.service(.userNotFound, "User not found in the system.", "Sign up."))
        }

        let deletion = Task { try await client.deleteUser() }
        await latch.waitForArrivals(1)
        deletion.cancel()
        await latch.open()
        let error = await authClientError { try await deletion.value }

        XCTAssertEqual(error?.kind, .service(.userNotFound))
        XCTAssertEqual(engine.revokeGlobalFlags, [true])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a signed-in session that needs no refresh
    /// - When: a caller already cancelled deletes the user
    /// - Then:
    ///    - it throws `CancellationError`; Cognito is never asked, and the session stays signed in with its row
    func testACallerCancelledBeforeCognitoIsAskedDeletesNothing() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()

        let deletion = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await client.deleteUser()
        }

        await assertThrowsAsync({ try await deletion.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        XCTAssertEqual(engine.deleteUserCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, alice.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }
}
