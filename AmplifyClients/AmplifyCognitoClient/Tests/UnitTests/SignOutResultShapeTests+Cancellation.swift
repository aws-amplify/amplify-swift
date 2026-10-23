//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The sign-out result when the calling task is cancelled.
extension SignOutResultShapeTests {

    // MARK: Cancellation

    /// - Given: a signed-in session, and a revoke cancelled before it revoked anything; then a sign-out from a
    ///   task already cancelled when it starts
    /// - When: each signs out
    /// - Then:
    ///    - each is `.failed(.unknown)` with exactly the decided description and suggestion, and a
    ///      `CancellationError` as its underlying error; the session is still signed in
    func testCancellationBeforeAnyRevokeIsFailedUnknownWithCancellationError() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        harness.engine(for: work)?.scriptRevoke { _ in throw CancellationError() }

        let cancelledRevoke = await client.signOut()
        let cancelledTask = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await client.signOut()
        }.value

        for result in [cancelledRevoke, cancelledTask] {
            guard case .failed(.unknown(let description, let suggestion, let underlying)) = result else {
                XCTFail("expected .failed(.unknown), got \(result)")
                continue
            }
            XCTAssertEqual(description, "The sign-out was cancelled before anything was revoked; the session is still signed in.")
            XCTAssertEqual(suggestion, "Retry the sign-out.")
            XCTAssertTrue(underlying is CancellationError, "\(String(describing: underlying))")
            XCTAssertFalse(result.signedOutLocally)
        }
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls.count, 1, "the cancelled task revoked nothing")
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// A revoke already sent when the caller is cancelled runs to its end, and the sign-out follows what it did:
    /// the engine's actions run in tasks of their own, so Cognito revokes the tokens whatever
    /// the caller does, and keeping the record would keep revoked tokens signed in.
    ///
    /// - Given: a session signed in over the live engine, and its `RevokeToken` held at scripted Cognito
    /// - When: the calling task is cancelled while `RevokeToken` is held, and `RevokeToken` then completes
    /// - Then:
    ///    - the result is `.complete`, signed out locally; `RevokeToken` was sent once; the record is signed out, and
    ///      so is the session in memory
    func testACallerCancelledWhileRevokeTokenIsInFlightStillSignsOut() async throws {
        let live = LiveEngineHarness()
        let client = try liveClient(live)
        try await signInAlice(client, live)
        let revoking = Gate()
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) in
            await revoking.pass()
            return RevokeTokenOutput()
        }
        live.cognito.clearCalls()
        let signOut = Task { await client.signOut() }
        await revoking.waitForArrivals(1)

        signOut.cancel()
        await revoking.open()

        let result = await signOut.value
        XCTAssertEqual(result, .complete)
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(live.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a session signed in over the live engine, and `RevokeToken` failing at Cognito while it is held
    /// - When: the calling task is cancelled while `RevokeToken` is held, and `RevokeToken` then fails
    /// - Then:
    ///    - the result is `.partial(revokeTokenError:)` with Cognito's failure, not a cancellation, signed out
    ///      locally; the record is signed out
    func testACallerCancelledWhileAFailingRevokeTokenIsInFlightIsPartial() async throws {
        let live = LiveEngineHarness()
        let client = try liveClient(live)
        try await signInAlice(client, live)
        let revoking = Gate()
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in
            await revoking.pass()
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        let signOut = Task { await client.signOut() }
        await revoking.waitForArrivals(1)

        signOut.cancel()
        await revoking.open()

        let result = await signOut.value
        XCTAssertTrue(result.signedOutLocally, "\(result)")
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        let revokeError = try XCTUnwrap(partial.revokeTokenError)
        XCTAssertFalse(revokeError.underlyingError is CancellationError, "\(revokeError)")
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// Over the live engine, a caller cancelled before its sign-out sends anything revokes nothing.
    ///
    /// - Given: a session signed in over the live engine
    /// - When: it signs out from a task already cancelled when it starts
    /// - Then:
    ///    - the result is `.failed(.unknown)` with a `CancellationError`; nothing was sent to Cognito; the
    ///      session is still signed in, stored and in memory
    func testALiveSignOutCancelledBeforeAnyRevokeIsFailedAndSendsNothing() async throws {
        let live = LiveEngineHarness()
        let client = try liveClient(live)
        try await signInAlice(client, live)
        live.scriptSignOut()
        live.cognito.clearCalls()
        let payload = try XCTUnwrap(harness.storedRecord(work)?.credentials)

        let result = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await client.signOut()
        }.value

        XCTAssertEqual(result, .failed(SessionSignOut.cancelledError()))
        XCTAssertEqual(live.cognito.operations, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// Once a revoke has completed, cancellation never stops the local clear.
    ///
    /// - Given: a session whose first revoke succeeds while the same user refreshes, and whose retry is cancelled
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.partial(revokeTokenError:)`, signed out locally, and the session is cleared
    func testCancellationAfterARevokeStillClears() async throws {
        try harness.signIn(work, .signedIn("alice", version: 1))
        let client = try harness.client(work)
        let store = harness.store()
        let revoked = Flag()
        harness.engine(for: work)?.scriptRevoke { [work] _ in
            guard !revoked.isRaised else {
                throw CancellationError()
            }
            revoked.raise()
            if case .record(let envelope) = try store.read(work),
               let current = envelope.record.credentials.flatMap(FakePayload.decode) {
                try store.write(current.refreshed.record(), for: work, expecting: envelope.version)
            }
        }

        let result = await client.signOut()

        XCTAssertTrue(result.signedOutLocally)
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        XCTAssertNotNil(partial.revokeTokenError)
        XCTAssertNil(partial.storageError)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }
}
