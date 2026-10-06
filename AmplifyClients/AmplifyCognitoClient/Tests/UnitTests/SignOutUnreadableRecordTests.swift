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
/// tokens this build could neither read nor revoke, so that sign-out is `.partial`, never `.complete`.
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

        XCTAssertEqual(result, .partial(
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

        XCTAssertEqual(newer, .partial(
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

    private func signOutStored(_ sessionId: SessionID) async -> AuthClientSignOutResult {
        await AmplifyCognitoClient.signOutStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
    }
}
