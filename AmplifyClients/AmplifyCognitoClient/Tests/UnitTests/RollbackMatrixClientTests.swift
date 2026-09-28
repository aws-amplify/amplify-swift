//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The rollback matrix, the client's side: an app moving from a build with only the Auth plugin to
/// a build with this client, or rolled forward to it again after a rollback, and the states the client leaves
/// for a rollback.
///
/// Each test names the matrix row it runs: `Matrix07` is a cell of the key matrix (which records exist: the
/// plugin's key only, the session key only, both, neither, or keys for several sessions; by the client's
/// column), `Matrix03` a row of the adoption-state table (states A1 to A6, from the plugin's record alone to
/// sessions created on the client), `Marker` the plugin's signed-out marker, and `FirstLoad` the rule that
/// `.default` reads the plugin's record at first load only (the plugin and the client side by side over the
/// default session is not supported). `docs/design/issues/rollback-behaviours.md` records the behaviours the
/// matrix found. The plugin's records are its own bytes: the frozen payload fixtures and the
/// stored-format goldens in the plugin's test resources, read in place. The client runs its real record store,
/// core and live engine over the in-memory keychain, with scripted Cognito. The plugin's half of each row is
/// in `RollbackMatrixPluginTests`.
final class RollbackMatrixClientTests: XCTestCase {

    private var harness: ClientHarness!
    private var live: LiveEngineHarness!

    private let fixtureUser = AuthClientUser(username: "fixture-user", userId: "fixture-sub")
    /// The user in the stored-format goldens: the same user name, another `sub`.
    private let goldenUser = AuthClientUser(username: "fixture-user", userId: "fixture-sub-0001")

    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
        live = LiveEngineHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
        live = nil
    }

    // MARK: - Matrix 07: plugin key only; matrix 03 rows 1 (A1) and 4 (A3)

    /// Matrix 07 row "Plugin key only", column `client (.default), read-through`; matrix 03 row 1 (A1)
    ///
    /// - Given: Only the plugin's record, as the plugin wrote it
    /// - When:
    ///    - `.default` reports its state and fetches its session
    /// - Then:
    ///    - It is signed in as the plugin's user, with the plugin's tokens, and writes and deletes nothing: the
    ///      plugin's record is byte-identical, so a rollback finds it (A1)
    ///
    func testMatrix07_pluginKeyOnly_readThrough_matrix03Row1_A1_isSignedInAndWritesNothing() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        let session = try await client.fetchAuthSession()

        XCTAssertEqual(state, .signedIn(fixtureUser))
        XCTAssertEqual(try session.userPoolTokensResult.get().refreshToken, EnginePayloadFixtures.refreshToken)
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:fixture-identity-id")
        XCTAssertEqual(harness.keychain.value(pluginAccount), payload)
        XCTAssertEqual(harness.keychain.mutationOrder, [])
        live.cognito.assertConsumed()
    }

    /// Matrix 07 row "Plugin key only", column `client (.default), after completeAdoption()`; it produces matrix
    /// 03 row 4 (A3)
    ///
    /// - Given: Only the plugin's record
    /// - When:
    ///    - `.default` completes adoption
    /// - Then:
    ///    - Its own record holds the plugin's payload verbatim, written (with its namespace marker, which names
    ///      the configuration it was written under) before the plugin's record is deleted, and it is still
    ///      signed in as the same user
    ///
    func testMatrix07_pluginKeyOnly_completeAdoption_matrix03Row4_A3_copiesThenDeletes() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        let client = try makeClient()

        try await client.completeAdoption()

        let own = try XCTUnwrap(harness.storedRecord(.default))
        XCTAssertEqual(own.credentials, payload)
        XCTAssertEqual(own.kind, .userPoolAndIdentityPool)
        XCTAssertEqual(own.username, "fixture-user")
        XCTAssertEqual(own.userId, "fixture-sub")
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(
            harness.keychain.mutationOrder,
            [.write(defaultAccount), .write(markerAccount(.default)), .remove(pluginAccount)]
        )
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(fixtureUser))
    }

    // MARK: - Matrix 07: session key only

    /// Matrix 07 row "Session key only (`.default`)", columns `client` read-through and after
    /// `completeAdoption()`
    ///
    /// - Given: Only `.default`'s own record, holding the plugin's payload
    /// - When:
    ///    - `.default` reports its state, then completes adoption
    /// - Then:
    ///    - It is signed in, adoption has nothing to do, and its record is byte-identical
    ///
    func testMatrix07_sessionKeyOnly_isSignedIn_andAdoptionChangesNothing() async throws {
        let own = try writeOwnRecord(EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        let client = try makeClient()

        let state = await client.currentSessionState()
        try await client.completeAdoption()
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(state, .signedIn(fixtureUser))
        XCTAssertEqual(harness.keychain.value(defaultAccount), own)
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertNil(harness.keychain.value(pluginAccount))
    }

    // MARK: - Matrix 07: both keys

    /// Matrix 07 row "Both keys", column `client (.default), read-through`
    ///
    /// - Given: `.default`'s own record for one user, and the plugin's record for another (the stored-format golden)
    /// - When:
    ///    - `.default` reports its state
    /// - Then:
    ///    - Its own record wins: it is signed in as its own user. The plugin's key is read once, only to warn that the
    ///      plugin holds another user, and is left as it is
    ///
    func testMatrix07_bothKeys_ownRecordWins_andThePluginKeyIsOnlyReadToWarn() async throws {
        let warningsBefore = SideBySideWarningCapture.shared.count
        try writeOwnRecord(EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        let pluginRecord = try goldenSession("session-userPoolAndIdentityPool")
        harness.keychain.put(pluginRecord, pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(state, .signedIn(fixtureUser))
        XCTAssertEqual(harness.keychain.readAccounts.count(where: { $0 == pluginAccount }), 1)
        XCTAssertEqual(SideBySideWarningCapture.shared.count - warningsBefore, 1)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount))
        XCTAssertEqual(harness.keychain.value(pluginAccount), pluginRecord)
    }

    /// Matrix 07 row "Both keys", column `client (.default), after completeAdoption()`
    ///
    /// - Given: `.default`'s own record beside the plugin's record, first holding the same session, then another
    ///   user's
    /// - When:
    ///    - `.default` completes adoption
    /// - Then:
    ///    - The same session: the plugin's key is deleted and the own record is unchanged
    ///    - Another user: adoption throws and both records are kept, since it deletes only what it adopted
    ///
    func testMatrix07_bothKeys_completeAdoption_deletesOnlyWhatItAdopted() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        let own = try writeOwnRecord(payload)
        harness.keychain.put(payload, pluginAccount)
        let client = try makeClient()

        try await client.completeAdoption()

        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(harness.keychain.value(defaultAccount), own)

        let otherUser = try goldenSession("session-userPoolAndIdentityPool")
        harness.keychain.put(otherUser, pluginAccount)
        await assertThrowsAsync({ try await client.completeAdoption() }) { error in
            guard case .unknown = error as? AuthClientError else {
                return XCTFail("Expected unknown, got \(error)")
            }
        }
        await settlePluginPrincipalCheck(of: client)
        XCTAssertEqual(harness.keychain.value(pluginAccount), otherUser)
        XCTAssertEqual(harness.keychain.value(defaultAccount), own)
    }

    /// Matrix 07 row "Both keys", column `client (.default), after completeAdoption()`, from matrix 03's A2: the
    /// realistic case, which takes A2 to A3
    ///
    /// - Given: A2: `.default`'s own record after its refresh rotated the refresh token, beside the plugin's older
    ///   copy of the same user's session (the stored-format golden), which is not byte-equal to it
    /// - When:
    ///    - `.default` completes adoption
    /// - Then:
    ///    - The plugin's older copy is deleted, by the same-user rule, and the own record is unchanged: A3
    ///
    func testMatrix07_bothKeys_completeAdoption_matrix03A2ToA3_deletesTheOlderCopyOfTheSameUser() async throws {
        let pluginCopy = try goldenSession("session-userPoolAndIdentityPool")
        let own = try writeOwnRecord(pluginRefreshed(pluginCopy, refreshToken: "rotated-by-the-client"))
        harness.keychain.put(pluginCopy, pluginAccount)
        let client = try makeClient()

        try await client.completeAdoption()

        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(harness.keychain.value(defaultAccount), own)
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        let state = await client.currentSessionState()
        await settlePluginPrincipalCheck(of: client)
        XCTAssertEqual(state, .signedIn(goldenUser))
    }

    // MARK: - Matrix 07: neither; matrix 03 row 6 (A5)

    /// Matrix 07 row "Neither", both `client` columns
    ///
    /// - Given: No record at either key
    /// - When:
    ///    - `.default` reports its state, then completes adoption
    /// - Then:
    ///    - It is signed out, and nothing is written
    ///
    func testMatrix07_neither_isSignedOutAndWritesNothing() async throws {
        let client = try makeClient()

        let state = await client.currentSessionState()
        try await client.completeAdoption()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// Matrix 03 row 6 (A5): the purge that leaves "Neither"
    ///
    /// - Given: The plugin's record and `.default`'s own record for the same session
    /// - When:
    ///    - `.default` is purged
    /// - Then:
    ///    - Both keys are gone, the plugin's first, so a rolled-back plugin finds nothing
    ///
    func testMatrix03Row6_A5_purgeRemovesBothRecords() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        try writeOwnRecord(payload)

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertNil(harness.keychain.value(defaultAccount))
        XCTAssertEqual(Array(harness.keychain.mutationOrder.prefix(2)), [.remove(pluginAccount), .remove(defaultAccount)])
    }

    // MARK: - Matrix 07: session keys for N > 1 sessions

    /// Matrix 07 row "Session keys for N > 1 sessions", both `client` columns
    ///
    /// - Given: The plugin's record, and records of two named sessions for other principals
    /// - When:
    ///    - Each session reports its state, the named sessions complete adoption, then `.default` does
    /// - Then:
    ///    - Each named session reads only its own record, never the plugin's, and its adoption is a no-op
    ///    - `.default` reads the plugin's record, and its adoption leaves the named records byte-identical
    ///
    func testMatrix07_namedSessions_eachReadsItsOwnRecord() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        let work = ClientFixtures.id("work")
        let home = ClientFixtures.id("home")
        let workRecord = try writeOwnRecord(goldenSession("session-userPoolOnly"), for: work)
        let homeRecord = try writeOwnRecord(EnginePayloadFixtures.data("identityPoolOnly"), for: home)
        let workClient = try makeClient(work)
        let homeClient = try makeClient(home)

        let workState = await workClient.currentSessionState()
        let homeState = await homeClient.currentSessionState()
        try await workClient.completeAdoption()
        try await homeClient.completeAdoption()

        XCTAssertEqual(workState, .signedIn(goldenUser))
        XCTAssertEqual(homeState, .guest)
        XCTAssertFalse(harness.keychain.readAccounts.contains(pluginAccount))
        XCTAssertEqual(harness.keychain.mutationOrder, [])

        let defaultClient = try makeClient()
        let defaultState = await defaultClient.currentSessionState()
        try await defaultClient.completeAdoption()

        XCTAssertEqual(defaultState, .signedIn(fixtureUser))
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(harness.keychain.value(account(work)), workRecord)
        XCTAssertEqual(harness.keychain.value(account(home)), homeRecord)
    }

    // MARK: - Matrix 03 rows 2 and 3 (A2)

    /// Matrix 03 rows 2 and 3 (A2): the first write in read-through, which leaves the plugin's record stale
    ///
    /// - Given: Only the plugin's record, with expired tokens (the stored-format golden)
    /// - When:
    ///    - `.default` fetches its session, which refreshes, and Cognito rotates the refresh token
    /// - Then:
    ///    - The refresh is sent with the plugin's refresh token and lands in `.default`'s own record
    ///    - The plugin's record is byte-identical: stale, and with rotation on its refresh token is now dead,
    ///      which is row 3's forced re-sign-in after a rollback
    ///
    func testMatrix03Rows2And3_A2_firstRefreshWritesOwnRecordAndKeepsThePluginRecord() async throws {
        let pluginRecord = try goldenSession("session-userPoolAndIdentityPool")
        harness.keychain.put(pluginRecord, pluginAccount)
        live.scriptRefresh("fixture-user")
        live.scriptIdentityPool()
        let client = try makeClient()

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(try session.userPoolTokensResult.get().refreshToken, "refresh-fixture-user-v2")
        XCTAssertEqual(
            live.cognito.inputs("GetTokensFromRefreshToken", as: GetTokensFromRefreshTokenInput.self).map(\.refreshToken),
            ["fixture-refresh-token"]
        )
        let own = try XCTUnwrap(harness.storedRecord(.default)?.credentials)
        XCTAssertEqual(try AmplifyCredentials.decoded(own).signedInData?.cognitoUserPoolTokens.refreshToken, "refresh-fixture-user-v2")
        XCTAssertEqual(harness.keychain.value(pluginAccount), pluginRecord)
        XCTAssertFalse(harness.keychain.removedAccounts.contains(pluginAccount))
    }

    // MARK: - Matrix 03 row 5 (A4)

    /// Matrix 03 row 5 (A4): a sign-out on the client, after adoption and in read-through
    ///
    /// - Given: The plugin's record, adopted into `.default`; separately, the plugin's record in read-through
    /// - When:
    ///    - `.default` signs out
    /// - Then:
    ///    - The row is kept with no credentials and the plugin's record is gone, so a rolled-back plugin cannot
    ///      bring the ended session back
    ///
    func testMatrix03Row5_A4_signOutKeepsASignedOutRowAndDeletesThePluginRecord() async throws {
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        for adopted in [true, false] {
            if !adopted {
                await harness.waitForBaseline()
                harness = ClientHarness()
                live = LiveEngineHarness()
            }
            live.scriptSignOut()
            harness.keychain.put(payload, pluginAccount)
            let client = try makeClient()
            if adopted {
                try await client.completeAdoption()
            }

            let result = try await client.signOut()

            XCTAssertEqual(result, .complete, "adopted: \(adopted)")
            let row = try XCTUnwrap(harness.storedRecord(.default), "adopted: \(adopted)")
            XCTAssertEqual(row.kind, SessionKind.signedOut, "adopted: \(adopted)")
            XCTAssertNil(row.credentials, "adopted: \(adopted)")
            XCTAssertNil(harness.keychain.value(pluginAccount), "adopted: \(adopted)")
            XCTAssertEqual(
                live.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token),
                [EnginePayloadFixtures.refreshToken],
                "adopted: \(adopted)"
            )
        }
    }

    // MARK: - Matrix 03 row 7 (A6)

    /// Matrix 03 row 7 (A6): sessions created on the client
    ///
    /// - Given: No plugin record
    /// - When:
    ///    - A named session and `.default` each sign in
    /// - Then:
    ///    - Each writes only its own `amplify.1.` record and its namespace marker; the plugin's key is never
    ///      written, so an `old` plugin finds nothing
    ///
    func testMatrix03Row7_A6_nativeSessionsNeverWriteThePluginRecord() async throws {
        let work = ClientFixtures.id("work")
        for sessionId in [work, SessionID.default] {
            live.scriptSRP()
            live.scriptIdentityPool()
            let client = try makeClient(sessionId)

            let result = try await client.signIn(username: "alice", password: "password")

            XCTAssertEqual(result.nextStep, .done, "\(sessionId)")
            XCTAssertNotNil(try harness.storedRecord(sessionId)?.credentials, "\(sessionId)")
        }
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount))
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(
            Set(harness.keychain.writtenAccounts),
            [account(work), markerAccount(work), defaultAccount, markerAccount(.default)]
        )
    }

    // MARK: - Matrix 03 row 9: the round trip

    /// Matrix 03 row 9 (A2, rolled back, then forward again), the client's half, with refresh-token rotation on
    ///
    /// - Given: `.default`'s own record with expired tokens, and the plugin's record, which the rolled-back plugin
    ///   refreshed and rotated, holding a newer session
    /// - When:
    ///    - `.default` reports its state and fetches its session, and Cognito rejects its refresh token as
    ///      reused, since the plugin's refresh rotated it away
    /// - Then:
    ///    - It resumes from its own older record, not the plugin's newer one, which it reads only once, for the
    ///      side-by-side check, and never writes. The plugin's record is the same user's, so nothing is logged
    ///    - The refresh is sent with its own dead token. The first reuse fails the fields as retryable: another
    ///      writer may still be saving the refresh that used the token. The second, `RefreshTokenReuse.minimumGap`
    ///      later with its record's credentials still unchanged, means nobody did: every field fails with
    ///      `sessionExpired`, so the app signs in again, and a third fetch sends no refresh (`docs/design/issues/rollback-behaviours.md` §3)
    ///    - It stays signed in as its user, as an expired session does
    ///
    func testMatrix03Row9_roundTrip_resumesOnItsOwnOlderRecord() async throws {
        let warningsBefore = SideBySideWarningCapture.shared.count
        let own = try writeOwnRecord(goldenSession("session-userPoolAndIdentityPool"))
        let rotated = try pluginRefreshed(goldenSession("session-userPoolAndIdentityPool"), refreshToken: "rotated-by-the-plugin")
        harness.keychain.put(rotated, pluginAccount)
        live.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw RefreshTokenReuseException(message: "Refresh token has been used")
        }
        let client = try makeClient()
        let events = StreamRecorder(client.listenToAuthEvents())

        let state = await client.currentSessionState()
        let session = try await client.fetchAuthSession()
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let again = try await client.fetchAuthSession()
        let third = try await client.fetchAuthSession()

        XCTAssertEqual(state, .signedIn(goldenUser))
        XCTAssertEqual(
            live.cognito.inputs("GetTokensFromRefreshToken", as: GetTokensFromRefreshTokenInput.self).map(\.refreshToken),
            ["fixture-refresh-token", "fixture-refresh-token"]
        )
        guard case .failure(.unknown(_, _, let underlying)) = session.userPoolTokensResult,
              case .refreshTokenReused = underlying as? SessionEngineError else {
            return XCTFail("Expected unknown caused by refreshTokenReused, got \(session.userPoolTokensResult)")
        }
        for fields in [again, third] {
            let results = [
                fields.userPoolTokensResult.map { _ in () },
                fields.userSubResult.map { _ in () },
                fields.identityIdResult.map { _ in () },
                fields.awsCredentialsResult.map { _ in () }
            ]
            for result in results {
                guard case .failure(let error) = result else {
                    XCTFail("Expected sessionExpired, got a value")
                    continue
                }
                XCTAssertEqual(error.kind, .sessionExpired)
            }
        }
        await events.waitFor(1)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(events.received, [.sessionExpired], "one event, and no late second one")
        XCTAssertEqual(harness.keychain.value(defaultAccount), own, "its own record is kept")
        let after = await client.currentSessionState()
        await settlePluginPrincipalCheck(of: client)
        XCTAssertEqual(after, .signedIn(goldenUser))
        XCTAssertEqual(harness.keychain.readAccounts.count(where: { $0 == pluginAccount }), 1)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount))
        XCTAssertEqual(SideBySideWarningCapture.shared.count - warningsBefore, 0)
        XCTAssertEqual(harness.keychain.value(pluginAccount), rotated)
    }

    // MARK: - Matrix 03 row 10: a newer schema

    /// Matrix 03 row 10 (a record written by a newer schema)
    ///
    /// - Given: A schema-2 record under `.default`'s schema-1 key, beside the plugin's record
    /// - When:
    ///    - `.default` reports its state, is labelled, and completes adoption
    /// - Then:
    ///    - It fails as a record from a newer version; labelling and adoption throw; nothing is written or
    ///      deleted, and the plugin's record is not adopted
    ///
    func testMatrix03Row10_newerSchemaUnderTheOwnKey_isLeftAlone() async throws {
        let versionTwo = Data(#"{"schemaVersion":2,"generation":1,"lastWriteTimestamp":0,"kind":"passkey"}"#.utf8)
        harness.keychain.put(versionTwo, defaultAccount)
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        await assertThrowsAsync({ try await client.setSessionLabel("Main") }) { _ in }
        await assertThrowsAsync({ try await client.completeAdoption() }) { _ in }

        guard case .failed = state else {
            return XCTFail("Expected failed, got \(state)")
        }
        XCTAssertEqual(harness.keychain.value(defaultAccount), versionTwo)
        XCTAssertEqual(harness.keychain.value(pluginAccount), payload)
        XCTAssertEqual(harness.keychain.mutationOrder, [])
    }

    /// Matrix 03 row 10 (a record under a newer schema's key, `amplify.2.`)
    ///
    /// - Given: `.default`'s schema-1 record, and a record under the matching `amplify.2.` account
    /// - When:
    ///    - `.default` reports its state, and the saved sessions are listed
    /// - Then:
    ///    - The schema-1 record is used, the `amplify.2.` record is not listed, and it is never written or deleted
    ///
    func testMatrix03Row10_newerSchemaKey_isSkipped() async throws {
        try writeOwnRecord(EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        let futureAccount = "amplify.2.\(StorageFixtures.pools.keyComponent).$default.session"
        let versionTwo = Data(#"{"schemaVersion":2,"generation":1,"lastWriteTimestamp":0,"kind":"passkey"}"#.utf8)
        harness.keychain.put(versionTwo, futureAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        await settlePluginPrincipalCheck(of: client)
        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: dependencies
        )

        XCTAssertEqual(state, .signedIn(fixtureUser))
        XCTAssertEqual(listed.map(\.sessionId), [.default])
        XCTAssertEqual(harness.keychain.value(futureAccount), versionTwo)
        XCTAssertEqual(harness.keychain.mutationOrder, [])
    }

    // MARK: - The signed-out marker, rolled forward

    /// The signed-out marker, rolled forward with no record of the client's own
    ///
    /// - Given: Only the plugin's signed-out marker, as the reader plugin writes it
    /// - When:
    ///    - `.default` reports its state and completes adoption
    /// - Then:
    ///    - It is signed out, nothing is adopted or written, and the marker is left as it is
    ///
    func testMarker_rolledForwardWithOnlyTheMarker_isSignedOut() async throws {
        let marker = try EnginePayloadFixtures.data("noCredentials")
        harness.keychain.put(marker, pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        try await client.completeAdoption()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertEqual(harness.keychain.value(pluginAccount), marker)
    }

    /// The signed-out marker, rolled forward in front of the client's own signed-in record
    ///
    /// - Given: `.default`'s own signed-in record, and the marker the reader plugin wrote when the user signed out
    ///   after a rollback
    /// - When:
    ///    - `.default` reports its state
    /// - Then:
    ///    - Its own record wins and it is signed in: the plugin's sign-out is not seen (pinned). The marker
    ///      is read once, for the side-by-side check, which it does not warn on
    ///
    func testMarker_rolledForwardInFrontOfTheOwnRecord_ownRecordWins() async throws {
        let warningsBefore = SideBySideWarningCapture.shared.count
        try writeOwnRecord(EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        harness.keychain.put(try EnginePayloadFixtures.data("noCredentials"), pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()
        await settlePluginPrincipalCheck(of: client)

        XCTAssertEqual(state, .signedIn(fixtureUser))
        XCTAssertEqual(harness.keychain.readAccounts.count(where: { $0 == pluginAccount }), 1)
        XCTAssertEqual(SideBySideWarningCapture.shared.count - warningsBefore, 0)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount))
    }

    // MARK: - The plugin's record is read at first load only

    /// `.default` reads the plugin's record only until it has its own
    ///
    /// - Given: `.default`'s own signed-out row (kept by an earlier sign-out), and a plugin record for a user the
    ///   rolled-back plugin signed in afterwards
    /// - When:
    ///    - `.default` reports its state
    /// - Then:
    ///    - It is signed out: the plugin's record is never read or adopted, and is left as it is
    ///
    func testFirstLoad_ownSignedOutRowShadowsALaterPluginSignIn() async throws {
        let signedOut = try harness.store().write(.signedOut(label: "Main", username: "fixture-user"), for: .default, expecting: nil)
        XCTAssertTrue(signedOut.didCommit)
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")
        harness.keychain.put(payload, pluginAccount)
        let client = try makeClient()

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedOut)
        XCTAssertFalse(harness.keychain.readAccounts.contains(pluginAccount))
        XCTAssertEqual(harness.keychain.value(pluginAccount), payload)
    }

    // MARK: - Helpers

    private var defaultAccount: String { account(.default) }

    /// The namespace marker a session's first signed-in record writes (`SessionRecordStore+CopyForward.swift`).
    private func markerAccount(_ sessionId: SessionID) -> String {
        SessionRecordKey.markerAccount(for: sessionId, scope: TestKeychain.markerScope)
    }

    private func account(_ sessionId: SessionID) -> String {
        SessionRecordKey.account(for: sessionId, in: StorageFixtures.pools, kind: .session)
    }

    /// The harness's dependencies, with the live engine over scripted Cognito in place of the fake engine.
    private var dependencies: SessionCoreDependencies {
        let base = harness.dependencies
        let live = live!
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try live.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = base.sheetLock
        #endif
        return dependencies
    }

    private func makeClient(_ sessionId: SessionID = .default) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: sessionId),
            dependencies: dependencies
        )
    }

    /// Writes `payload` as `sessionId`'s own signed-in record, as the client stores a session it signed in or
    /// adopted, then clears the keychain logs. Returns the stored bytes.
    @discardableResult
    private func writeOwnRecord(_ payload: Data, for sessionId: SessionID = .default) throws -> Data {
        let summary = PluginRecordSummary.peek(payload)
        let record = SessionRecord(
            label: nil,
            username: summary.username,
            userId: summary.userId,
            kind: summary.kind,
            credentials: payload
        )
        XCTAssertTrue(try harness.store().write(record, for: sessionId, expecting: nil).didCommit)
        harness.keychain.resetLogs()
        return try XCTUnwrap(harness.keychain.value(account(sessionId)))
    }

    /// A stored-format golden from the plugin's test resources, without the file's trailing newline. Its tokens
    /// expired in 2023.
    private func goldenSession(_ name: String) throws -> Data {
        var data = try Data(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // UnitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // AmplifyCognitoClient
            .deletingLastPathComponent() // AmplifyClients
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenStoredFormat")
            .appendingPathComponent("\(name).json"))
        if data.last == UInt8(ascii: "\n") {
            data.removeLast()
        }
        return data
    }

    /// The plugin's frozen payload with its refresh token replaced, as the plugin stores it after a refresh
    /// that rotated the token: the same encoder, one value changed.
    private func pluginRefreshed(_ payload: Data, refreshToken: String) throws -> Data {
        let text = String(decoding: payload, as: UTF8.self)
        let replaced = text.replacingOccurrences(
            of: #""refreshToken":"\#(EnginePayloadFixtures.refreshToken)""#,
            with: #""refreshToken":"\#(refreshToken)""#
        )
        XCTAssertNotEqual(replaced, text)
        return Data(replaced.utf8)
    }
}
