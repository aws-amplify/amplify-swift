//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A sign-out over a record this build cannot read replaces it with a signed-out row. A newer schema's record may hold
/// tokens this build could neither read nor revoke, so that sign-out is `.partial`, never `.complete`. A readable
/// record with no credentials under a kind that holds them is reset the same way, keeping its label and user.
final class SignOutUnreadableRecordTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: a named session whose record a newer version of the app saved (schema 2)
    /// - When: it signs out through its client
    /// - Then:
    ///    - the result is `.partial` with a revoke error naming the schema and saying a refresh token it held stays
    ///      valid; nothing was revoked; the record is a signed-out row; the session is signed out and sends `.signedOut`
    func testSigningOutANewerSchemasRecordIsPartial() async throws {
        let store = harness.store()
        harness.keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: work))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = await client.signOut()

        XCTAssertEqual(result, .partialResult(
            revokeTokenError: SessionSignOut.unrevokedNewerRecordError(version: 2),
            globalSignOutError: nil,
            hostedUIError: nil,
            storageError: nil
        ))
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await waitUntil("the session sends .signedOut") { events.received == [.signedOut] }
    }

    /// - Given: a named session whose record a newer version of the app saved (schema 2)
    /// - When: it signs out globally through its client
    /// - Then:
    ///    - the result is `.partial` with the same error as both its revoke and its global sign-out error, since no
    ///      global sign-out was sent; nothing was revoked; the record is a signed-out row
    func testSigningOutANewerSchemasRecordGloballyReportsTheGlobalSignOutAsFailed() async throws {
        let store = harness.store()
        harness.keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: work))
        let client = try harness.client(work)
        _ = await client.currentSessionState()

        let result = await client.signOut(options: AmplifyCognitoClientSignOutOptions(globalSignOut: true))

        let unrevoked = SessionSignOut.unrevokedNewerRecordError(version: 2)
        XCTAssertEqual(result, .partialResult(
            revokeTokenError: unrevoked,
            globalSignOutError: unrevoked,
            hostedUIError: nil,
            storageError: nil
        ))
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: one named session whose record a newer version saved, and another whose record is corrupt bytes, neither
    ///   held by a client
    /// - When: each is signed out with `signOutStoredSession`
    /// - Then:
    ///    - the newer schema's is `.partial`, with the same revoke error; the corrupt one is `.complete`, as before, since
    ///      nothing shows it held any tokens; both records are signed-out rows
    func testTheStaticSignOutReportsTheSame() async throws {
        let store = harness.store()
        harness.keychain.put(StorageFixtures.futureSchemaRecord, store.sessionAccount(for: work))
        harness.keychain.put(StorageFixtures.corruptRecord, store.sessionAccount(for: home))

        let newer = await signOutStored(work)
        let corrupt = await signOutStored(home)

        XCTAssertEqual(newer, .partialResult(
            revokeTokenError: SessionSignOut.unrevokedNewerRecordError(version: 2),
            globalSignOutError: nil,
            hostedUIError: nil,
            storageError: nil
        ))
        XCTAssertEqual(corrupt, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        XCTAssertEqual(try harness.storedRecord(home)?.isSignedOut, true)
    }

    // MARK: A kind that holds credentials, and none

    /// A record with a signed-in kind, a label and a user, and no credentials: no build saves one, and a restore of it
    /// is `.failed`.
    private let withoutCredentials = SessionRecord(label: "Work", username: "alice", userId: "sub-alice", kind: .userPoolOnly, credentials: nil)

    private func listedStates() async throws -> [AuthSessionState] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: harness.dependencies
        ).map(\.state)
    }

    /// A sign-out resets a record a restore cannot use, as the `.failed` state's own text says it does.
    ///
    /// - Given: a named session whose record has a signed-in kind and no credentials, restored `.failed` by its client
    /// - When: it signs out through its client
    /// - Then:
    ///    - the result is `.complete`, and nothing was revoked
    ///    - the record is a signed-out row that keeps the label and the user, listed `.signedOut`
    ///    - the client is `.signedOut`
    func testSigningOutARecordWithAKindAndNoCredentialsResetsIt() async throws {
        try harness.store().write(withoutCredentials, for: work, expecting: nil)
        let client = try harness.client(work)
        let restored = await client.currentSessionState()

        let result = await client.signOut()

        guard case .failed(.unknown) = restored else {
            return XCTFail("restored \(restored)")
        }
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        let listed = try await listedStates()
        XCTAssertEqual(listed, [.signedOut])
    }

    /// - Given: a named session whose record has a signed-in kind and no credentials, held by no client
    /// - When: it is signed out with `signOutStoredSession`
    /// - Then:
    ///    - the result is `.complete`, and nothing was revoked
    ///    - the record is a signed-out row that keeps the label and the user, listed `.signedOut`, and a client built
    ///      for the session restores `.signedOut`
    func testTheStaticSignOutResetsARecordWithAKindAndNoCredentials() async throws {
        try harness.store().write(withoutCredentials, for: work, expecting: nil)
        let before = try await listedStates()

        let result = await signOutStored(work)

        XCTAssertEqual(before.count, 1)
        guard case .failed(.unknown)? = before.first else {
            return XCTFail("listed \(before)")
        }
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
        let listed = try await listedStates()
        XCTAssertEqual(listed, [.signedOut])
        let restored = try await harness.client(work).currentSessionState()
        XCTAssertEqual(restored, .signedOut)
    }

    /// A record that turns up without credentials during the revoke is left, like one that turns up unreadable, and not
    /// reported as signed out over a row that is still `.failed`.
    ///
    /// - Given: a signed-in session, and a revoke during which another writer replaces its record with one that has a
    ///   signed-in kind and no credentials
    /// - When: it signs out, then signs out again
    /// - Then:
    ///    - the first is `.failed(.unknown)`, saying the record became unreadable and was left as it is
    ///    - the second is `.complete`, and resets it: the record is a signed-out row, and the client `.signedOut`
    func testARecordLeftWithoutCredentialsDuringTheRevokeIsLeftThenReset() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        harness.engine(for: work)?.scriptRevoke { [work, withoutCredentials] _ in
            if case .record(let stored) = try store.read(work) {
                try store.write(withoutCredentials, for: work, expecting: stored.version)
            }
        }

        let first = await client.signOut()
        let second = await client.signOut()

        guard case .failed(let error) = first else {
            return XCTFail("the first sign-out is \(first)")
        }
        XCTAssertEqual(error.errorDescription, SessionSignOut.unreadableError(.corrupt).errorDescription)
        XCTAssertEqual(second, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls.count, 1)
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// The same, when the record turns up without credentials after the revoke, under the store's own sign-out.
    ///
    /// - Given: a signed-in session, and another writer that replaces its record with one that has a signed-in kind
    ///   and no credentials right after the sign-out's second read of it, which is after the revoke
    /// - When: it signs out, then signs out again
    /// - Then:
    ///    - the first is `.failed(.unknown)`, saying the record became unreadable and was left as it is
    ///    - the second is `.complete`, and resets it: the record is a signed-out row, and the client `.signedOut`
    func testARecordLeftWithoutCredentialsAfterTheRevokeIsLeftThenReset() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        harness.keychain.onceAfterReading(store.sessionAccount(for: work), occurrence: 2) { [work, withoutCredentials] in
            if case .record(let stored)? = try? store.read(work) {
                _ = try? store.write(withoutCredentials, for: work, expecting: stored.version)
            }
        }

        let first = await client.signOut()
        let second = await client.signOut()

        guard case .failed(let error) = first else {
            return XCTFail("the first sign-out is \(first)")
        }
        XCTAssertEqual(error.errorDescription, SessionSignOut.unreadableError(.corrupt).errorDescription)
        XCTAssertEqual(second, .complete)
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    private func signOutStored(_ sessionId: SessionID) async -> AmplifyCognitoClientSignOutResult {
        await AmplifyCognitoClient.signOutStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
    }
}
