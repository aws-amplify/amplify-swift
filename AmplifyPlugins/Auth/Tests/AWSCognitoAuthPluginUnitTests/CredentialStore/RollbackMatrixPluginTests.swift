//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import XCTest
@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// swiftlint:disable file_length type_body_length
/// The rollback matrix, the plugin's side: an app rolled back from a build with the Cognito client to a
/// build with only this plugin.
///
/// Each test names the matrix row it runs. `Matrix07` is the cell matrix: which keys the keychain holds
/// (plugin key only, session key only, both, neither, session keys for N > 1 sessions), read by each plugin
/// binary. `Matrix03` is the adoption-state matrix, whose states are A1 (read-through, no write yet), A2 (the
/// plugin's record beside the client's record for the same user), A3 (the client's record only, after
/// `completeAdoption()`), A4 (signed out on the client), A5 (purged) and A6 (`.default` created on the
/// client). `Marker` is the plugin's signed-out marker. See also `docs/design/issues/rollback-behaviours.md`.
/// Each seeds the keychain with the bytes the client leaves, written by the client's own record store,
/// or with the plugin's frozen payload and stored-format goldens, and runs the plugin's real credential store.
///
/// The `old` column is a released plugin from before the forward-compatible reader, emulated by
/// `ReleasedPluginKeychainView`; the `reader` column is this plugin.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the `@Sendable` closures the
///   production API takes. `XCTestCase` is not `Sendable`, and each test runs alone.
final class RollbackMatrixPluginTests: XCTestCase, @unchecked Sendable {

    private let authConfiguration = Defaults.makeDefaultAuthConfigData()
    private let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: Defaults.userPoolId, identityPoolId: Defaults.identityPoolId)
    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: pools) }
    private var clientAccount: String { SessionRecordKey.account(for: .default, in: pools, kind: .session) }

    private var keychain: InMemoryKeychain!
    private var pluginKeychain: InMemoryPluginKeychainStore!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
    }

    override func tearDown() async throws {
        keychain = nil
        pluginKeychain = nil
        await Amplify.reset()
    }

    // MARK: - The bytes

    /// The client's record, as this suite seeds it, is the client's frozen format
    ///
    /// - Given: The plugin's frozen `userPoolAndIdentityPool` payload
    /// - When:
    ///    - The client's record store writes it as the default session's record
    /// - Then:
    ///    - The stored bytes are exactly the client's schema-1 envelope around the payload, under the client's
    ///      exact account, so every test below reads what a client build leaves
    ///
    func testMatrixBytes_clientRecordIsTheFrozenEnvelope() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")

        let written = try RollbackMatrixBytes.writeClientRecord(payload, label: "Work", in: keychain, pools: pools)

        let base64 = payload.base64EncodedString().replacingOccurrences(of: "/", with: "\\/")
        let expected = #"{"credentials":"\#(base64)","generation":1,"kind":"userPoolAndIdentityPool","label":"Work","#
            + #""lastWriteTimestamp":1790000000000,"schemaVersion":1,"userId":"fixture-sub","username":"fixture-user"}"#
        XCTAssertEqual(String(bytes: written, encoding: .utf8), expected)
        XCTAssertEqual(clientAccount, "amplify.1.\(Defaults.userPoolId).\(Defaults.identityPoolId).$default.session")
        XCTAssertEqual(pluginAccount, "amplify.\(Defaults.userPoolId).\(Defaults.identityPoolId).session")
    }

    // MARK: - Matrix 07: plugin key only; matrix 03 row 1 (A1)

    /// Matrix 07 row "Plugin key only", columns `old` and `reader`; matrix 03 row 1 (A1, read-through with no
    /// write yet)
    ///
    /// - Given: Only the plugin's record, as the plugin wrote it (a client in read-through leaves it untouched)
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - Both are signed in with exactly that record, neither reads the client's key, and nothing is written
    ///
    func testMatrix07_pluginKeyOnly_matrix03Row1_A1_everyPluginIsSignedIn() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)

        for binary in RollbackPluginBinary.allCases {
            let store = makeStore(binary)

            XCTAssertEqual(try store.retrieveCredential(), try decoded(payload), "\(binary)")
            XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount), "\(binary)")
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), payload, "\(binary)")
        }
    }

    // MARK: - Matrix 07: session key only; matrix 03 rows 4 (A3) and 7 (A6)

    /// Matrix 07 row "Session key only", columns `old` and `reader`; matrix 03 row 4 (A3, after
    /// `completeAdoption()`) and row 7 (A6, `.default` created on the client)
    ///
    /// - Given: Only the client's default-session record, as the client's store writes it: the plugin's payload,
    ///   adopted verbatim or signed in natively
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - `old` finds nothing: signed out, the documented cost
    ///    - `reader` is signed in with exactly the record's credentials
    ///    - Neither writes anything, and the client's record is byte-identical
    ///
    func testMatrix07_sessionKeyOnly_matrix03Rows4And7_oldIsSignedOut_readerIsSignedIn() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        let written = try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)

        let old = makeStore(.old)
        XCTAssertThrowsError(try old.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        let reader = makeStore(.reader)
        XCTAssertEqual(try reader.retrieveCredential(), try decoded(payload))

        XCTAssertEqual(keychain.mutations, [])
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written)
    }

    // MARK: - Matrix 07: both keys

    /// Matrix 07 row "Both keys", columns `old` and `reader`
    ///
    /// - Given: The plugin's record for one session and the client's default-session record for another
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - Both read the plugin's record; the reader prefers its own key and never reads the client's
    ///
    func testMatrix07_bothKeys_everyPluginReadsItsOwnRecord() throws {
        let own = try RollbackMatrixBytes.pluginPayload("userPoolOnly")
        try RollbackMatrixBytes.writeClientRecord(
            RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool"),
            in: keychain,
            pools: pools
        )
        try RollbackMatrixBytes.put(own, pluginAccount, in: keychain)

        for binary in RollbackPluginBinary.allCases {
            XCTAssertEqual(try makeStore(binary).retrieveCredential(), try decoded(own), "\(binary)")
            XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount), "\(binary)")
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
        }
    }

    // MARK: - Matrix 07: neither; matrix 03 row 6 (A5)

    /// Matrix 07 row "Neither", columns `old` and `reader`; matrix 03 row 6 (A5, purged)
    ///
    /// - Given: A client default session and the plugin's record, then the client purges the session
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - Both keys are gone, both binaries are signed out, and nothing is written
    ///
    func testMatrix07_neither_matrix03Row6_A5_everyPluginIsSignedOut() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)
        try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)
        try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).purge(.default)
        keychain.resetMutations()
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: clientAccount))

        for binary in RollbackPluginBinary.allCases {
            XCTAssertThrowsError(try makeStore(binary).retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
        }
    }

    // MARK: - Matrix 07: session keys for N > 1 sessions

    /// Matrix 07 row "Session keys for N > 1 sessions", columns `old` and `reader`
    ///
    /// - Given: Records for two named client sessions and no plugin record; then also a default-session record
    /// - When:
    ///    - Each plugin binary retrieves its credentials, before and after the default record exists
    /// - Then:
    ///    - With only named sessions both are signed out; with the default record too, `old` is still signed
    ///      out and `reader` reads the default record only
    ///    - Neither ever reads a named session's key, and nothing is written
    ///
    func testMatrix07_namedSessions_pluginsReadOnlyTheDefaultRecord() throws {
        let work = try SessionID.named("work")
        let home = try SessionID.named("home")
        try RollbackMatrixBytes.writeClientRecord(RollbackMatrixBytes.pluginPayload("userPoolOnly"), for: work, in: keychain, pools: pools)
        try RollbackMatrixBytes.writeClientRecord(RollbackMatrixBytes.pluginPayload("identityPoolOnly"), for: home, in: keychain, pools: pools)
        let namedAccounts = [work, home].map { SessionRecordKey.account(for: $0, in: pools, kind: .session) }

        for binary in RollbackPluginBinary.allCases {
            XCTAssertThrowsError(try makeStore(binary).retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
        }

        let defaultPayload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(defaultPayload, in: keychain, pools: pools)
        XCTAssertThrowsError(try makeStore(.old).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        XCTAssertEqual(try makeStore(.reader).retrieveCredential(), try decoded(defaultPayload))

        XCTAssertEqual(pluginKeychain.readAccounts.filter(namedAccounts.contains), [])
        XCTAssertEqual(keychain.mutations, [])
    }

    // MARK: - Matrix 03 row 5 (A4)

    /// Matrix 03 row 5 (A4, signed out on the client)
    ///
    /// - Given: The plugin's record and the client's default-session record, then the client signs the session
    ///   out: the row is kept with no credentials, and the plugin's record is deleted
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - Both are signed out, not resurrected, and nothing is written
    ///
    func testMatrix03Row5_A4_clientSignedOut_everyPluginIsSignedOut() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)
        try RollbackMatrixBytes.writeClientRecord(payload, label: "Work", in: keychain, pools: pools)
        let signedOutRow = try RollbackMatrixBytes.signOutClientRecord(in: keychain, pools: pools)
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertEqual(
            String(bytes: signedOutRow, encoding: .utf8),
            #"{"generation":2,"kind":"none","label":"Work","lastWriteTimestamp":1790000000000,"schemaVersion":1,"#
                + #""userId":"fixture-sub","username":"fixture-user"}"#
        )

        for binary in RollbackPluginBinary.allCases {
            XCTAssertThrowsError(try makeStore(binary).retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
        }
    }

    // MARK: - Matrix 03 row 8: mixed binaries

    /// Matrix 03 row 8 (A2 or A3 with a plugin-only extension beside a client app)
    ///
    /// - Given: A2 (the plugin's stale record beside the client's record for the same user, whose refresh token
    ///   the client's refresh rotated), then A3 (the client's record only)
    /// - When:
    ///    - The extension's plugin and the app's client each read, over the same keychain
    /// - Then:
    ///    - Under A2 they read different records for one user, with different refresh tokens: two live sessions
    ///      over one user
    ///    - Under A3 an `old` extension is signed out while the app is signed in; a `reader` extension reads
    ///      the app's record
    ///
    func testMatrix03Row8_mixedBinaries_extensionAndAppReadDifferentRecords() throws {
        let seeded = try seedA2()
        let (stale, fresh) = (seeded.stale, seeded.client)
        let client = RollbackMatrixBytes.clientStore(in: keychain, pools: pools)

        for binary in RollbackPluginBinary.allCases {
            // The two records differ only in the refresh token, so equality says which one was read.
            XCTAssertEqual(try makeStore(binary).retrieveCredential(), try decoded(stale), "\(binary)")
        }
        guard case .record(let envelope) = try client.read(.default) else {
            return XCTFail("The client should read its own record")
        }
        XCTAssertEqual(envelope.record.credentials, fresh)
        XCTAssertEqual(envelope.record.userId, userId(in: stale))
        XCTAssertEqual(refreshToken(in: fresh), clientRotatedRefreshToken)

        keychain.store(service: pluginKeychainService).removeIgnoringErrors(pluginAccount)
        XCTAssertThrowsError(try makeStore(.old).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        XCTAssertEqual(try makeStore(.reader).retrieveCredential(), try decoded(fresh))
        guard case .record = try client.read(.default) else {
            return XCTFail("The client should still read its own record")
        }
    }

    // MARK: - Matrix 03 row 10: a newer schema

    /// Matrix 03 row 10 (a record written by a newer schema)
    ///
    /// - Given: A schema-2 record under the client's schema-1 default account, and a record under an
    ///   `amplify.2.` account
    /// - When:
    ///    - Each plugin binary retrieves its credentials and signs out, first with no plugin record and then
    ///      with one
    /// - Then:
    ///    - Neither record is ever read as a session, written or deleted: without a plugin record both binaries
    ///      are signed out, and with one both read it
    ///
    func testMatrix03Row10_newerSchemaRecords_areLeftAlone() throws {
        let versionTwo = Data(#"{"schemaVersion":2,"generation":1,"lastWriteTimestamp":0,"kind":"passkey","credentials":"e30="}"#.utf8)
        let futureAccount = "amplify.2.\(Defaults.userPoolId).\(Defaults.identityPoolId).$default.session"
        try RollbackMatrixBytes.put(versionTwo, clientAccount, in: keychain)
        try RollbackMatrixBytes.put(versionTwo, futureAccount, in: keychain)
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolOnly")

        for binary in RollbackPluginBinary.allCases {
            keychain.store(service: pluginKeychainService).removeIgnoringErrors(pluginAccount)
            XCTAssertThrowsError(try makeStore(binary).retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)
            let store = makeStore(binary)
            XCTAssertEqual(try store.retrieveCredential(), try decoded(payload), "\(binary)")
            try store.deleteCredential()

            XCTAssertFalse(keychain.mutatedAccounts.contains(clientAccount), "\(binary)")
            XCTAssertFalse(keychain.mutatedAccounts.contains(futureAccount), "\(binary)")
            XCTAssertFalse(pluginKeychain.readAccounts.contains(futureAccount), "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), versionTwo, "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: futureAccount), versionTwo, "\(binary)")
        }
    }

    // MARK: - The signed-out marker

    /// The signed-out marker: a reader plugin signing out beside a client record
    ///
    /// - Given: Only the client's default-session record, which the reader plugin signs in from
    /// - When:
    ///    - The reader plugin signs out, and each plugin binary then retrieves its credentials
    /// - Then:
    ///    - The plugin's record is exactly its `noCredentials` payload, byte for byte, and every binary reads
    ///      it as no session; the client's record is byte-identical and was never written
    ///
    func testMarker_readerSignOutBesideAClientRecord_writesTheMarker_everyPluginStaysSignedOut() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        let written = try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)
        let reader = makeStore(.reader)
        XCTAssertEqual(try reader.retrieveCredential(), try decoded(payload))

        try reader.deleteCredential()

        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), try RollbackMatrixBytes.signedOutMarker())
        for binary in RollbackPluginBinary.allCases {
            XCTAssertEqual(try makeStore(binary).retrieveCredential(), .noCredentials, "\(binary)")
        }
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// The signed-out marker is only written by the reader: an `old` plugin signing out beside a client record
    /// deletes its own, and a later reader plugin then reads the client's record
    ///
    /// - Given: A2, the plugin's record beside the client's default-session record
    /// - When:
    ///    - The app rolls back to an `old` plugin and the user signs out; then the app moves to a `reader`
    ///      plugin
    /// - Then:
    ///    - The `old` plugin deletes its record (it cannot see the client's, so it writes no marker)
    ///    - The `reader` plugin then finds no record of its own and signs the user in from the client's record:
    ///      the session the user ended comes back (pinned; see `docs/design/issues/rollback-behaviours.md` §2)
    ///
    func testMarker_oldPluginSignOutBesideAClientRecord_readerPluginReadsTheClientRecordAgain() throws {
        let seeded = try seedA2()
        let (fresh, written) = (seeded.client, seeded.written)

        try makeStore(.old).deleteCredential()

        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertEqual(try makeStore(.reader).retrieveCredential(), try decoded(fresh))
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    // MARK: - Matrix 03 rows 2, 3 and 9: the whole plugin, refreshing

    /// Matrix 03 row 2 (A2, refresh-token rotation off)
    ///
    /// - Given: A2: the plugin's record as the client found it (expired tokens), beside the client's fresher
    ///   default-session record
    /// - When:
    ///    - Each plugin binary is configured and fetches the session, and Cognito accepts the stale refresh token
    /// - Then:
    ///    - It is signed in after one refresh, sent with the plugin record's refresh token
    ///    - The refresh lands in the plugin's record; the client's record is never read or written
    ///
    func testMatrix03Row2_A2RotationOff_everyPluginIsSignedInAfterOneRefresh() async throws {
        for binary in RollbackPluginBinary.allCases {
            let seeded = try seedA2()
            let (stale, written) = (seeded.stale, seeded.written)
            let sent = RecordedStrings()
            let refreshed = LongLivedCredentials.tokens(username: "fixture-user")
            let plugin = makePlugin(binary, userPool: MockIdentityProvider(
                mockGetTokensFromRefreshTokenResponse: { input in
                    sent.append(input.refreshToken)
                    return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                        accessToken: refreshed.accessToken,
                        expiresIn: 3_600,
                        idToken: refreshed.idToken
                    ))
                }
            ))

            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

            XCTAssertTrue(session.isSignedIn, "\(binary)")
            XCTAssertEqual(try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get().idToken, refreshed.idToken, "\(binary)")
            XCTAssertEqual(sent.values, [refreshToken(in: stale)], "\(binary)")
            XCTAssertNotEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), stale, "\(binary)")
            XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount), "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written, "\(binary)")
            XCTAssertEqual(keychain.mutatedClientAccounts, [], "\(binary)")
        }
    }

    /// Matrix 03 row 3 (A2, refresh-token rotation on): the forced re-sign-in, which applies to the reader
    /// plugin too
    ///
    /// - Given: A2: the plugin's record as the client found it, whose refresh token the client's refresh has
    ///   already rotated away, beside the client's record holding the live one
    /// - When:
    ///    - Each plugin binary is configured and fetches the session, and Cognito rejects the stale refresh token
    /// - Then:
    ///    - The session is signed in but no token can be fetched: every refresh fails with the service error
    ///      that wraps `RefreshTokenReuseException`, until the user signs in again (not `sessionExpired`; see
    ///      `docs/design/issues/rollback-behaviours.md` §1)
    ///    - The client's record, which holds a working refresh token, is never read or written
    ///
    func testMatrix03Row3_A2RotationOn_everyPluginForcesReSignIn() async throws {
        for binary in RollbackPluginBinary.allCases {
            let seeded = try seedA2()
            let (stale, written) = (seeded.stale, seeded.written)
            let staleToken = try XCTUnwrap(refreshToken(in: stale))
            let sent = RecordedStrings()
            let refreshed = LongLivedCredentials.tokens(username: "fixture-user")
            let plugin = makePlugin(binary, userPool: MockIdentityProvider(
                mockGetTokensFromRefreshTokenResponse: { input in
                    sent.append(input.refreshToken)
                    // Rotation: only the token the client's refresh rotated away is refused.
                    guard input.refreshToken != staleToken else {
                        throw AWSCognitoIdentityProvider.RefreshTokenReuseException(message: "Refresh token has been used")
                    }
                    return GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                        accessToken: refreshed.accessToken,
                        expiresIn: 3_600,
                        idToken: refreshed.idToken
                    ))
                }
            ))

            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
            let again = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

            for (attempt, session) in [session, again].enumerated() {
                let label = "\(binary), fetch \(attempt + 1)"
                XCTAssertTrue(session.isSignedIn, label)
                let tokens = try XCTUnwrap(session as? AuthCognitoTokensProvider, label).getCognitoTokens()
                // Not `sessionExpired`: the plugin reports a rotated-away refresh token as a service error, and
                // its Hub handler sends `sessionExpired` only for a `.sessionExpired` token failure
                // (`AuthHubEventHandler.handleSessionEvent`), so an app that waits for it is not told to sign in.
                guard case .failure(.service(_, _, let underlying)) = tokens,
                      underlying is AWSCognitoIdentityProvider.RefreshTokenReuseException else {
                    XCTFail("\(label): expected a service error caused by RefreshTokenReuseException, got \(tokens)")
                    continue
                }
                XCTAssertThrowsError(try XCTUnwrap(session as? AuthCognitoIdentityProvider, label).getIdentityId().get(), label)
                XCTAssertThrowsError(try XCTUnwrap(session as? AuthAWSCredentialsProvider, label).getAWSCredentials().get(), label)
            }
            XCTAssertEqual(sent.values, [staleToken, staleToken], "\(binary)")
            XCTAssertFalse(pluginKeychain.readAccounts.contains(clientAccount), "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written, "\(binary)")
            XCTAssertEqual(keychain.mutatedClientAccounts, [], "\(binary)")
        }
    }

    /// Matrix 03 row 9 (A2, rolled back, then forward again), the plugin's half
    ///
    /// - Given: A2, and a plugin whose refresh rotates the refresh token
    /// - When:
    ///    - Each plugin binary fetches the session, which refreshes and stores the rotated token
    /// - Then:
    ///    - The rotated token is only in the plugin's record; the client's record is byte-identical, so the client,
    ///      rolled forward, reads its own older record (the client's half is in `RollbackMatrixClientTests`)
    ///
    func testMatrix03Row9_roundTrip_pluginRefreshLandsOnlyInItsOwnRecord() async throws {
        for binary in RollbackPluginBinary.allCases {
            let seeded = try seedA2()
            let (client, written) = (seeded.client, seeded.written)
            let refreshed = LongLivedCredentials.tokens(username: "fixture-user")
            let plugin = makePlugin(binary, userPool: MockIdentityProvider(
                mockGetTokensFromRefreshTokenResponse: { _ in
                    GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                        accessToken: refreshed.accessToken,
                        expiresIn: 3_600,
                        idToken: refreshed.idToken,
                        refreshToken: "rotated-by-the-plugin"
                    ))
                }
            ))

            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

            XCTAssertTrue(session.isSignedIn, "\(binary)")
            let pluginRecord = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: pluginAccount))
            XCTAssertEqual(refreshToken(in: pluginRecord), "rotated-by-the-plugin", "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientAccount), written, "\(binary)")
            guard case .record(let envelope) = try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).read(.default) else {
                XCTFail("\(binary): the client should read its own record")
                continue
            }
            XCTAssertEqual(envelope.record.credentials, client, "\(binary)")
            XCTAssertEqual(refreshToken(in: client), clientRotatedRefreshToken, "\(binary)")
        }
    }

    // MARK: - Helpers

    private func makePlugin(_ binary: RollbackPluginBinary, userPool: CognitoUserPoolBehavior) -> AWSCognitoAuthPlugin {
        makePluginOverKeychain(binary.keychainStore(over: pluginKeychain), authConfiguration: authConfiguration, userPool: userPool)
    }

    private func makeStore(_ binary: RollbackPluginBinary) -> AWSCognitoAuthCredentialStore {
        let store = AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration, keychain: binary.keychainStore(over: pluginKeychain))
        // Construction records the configuration; only what the test does next is of interest.
        keychain.resetMutations()
        return store
    }

    /// What `seedA2()` stored.
    private struct A2Records {
        /// The plugin's record, as the client found it.
        let stale: Data
        /// The payload in the client's record: the same session, with the rotated refresh token.
        let client: Data
        /// The client's record, as stored.
        let written: Data
    }

    /// The refresh token the client's refresh rotated to in state A2.
    private let clientRotatedRefreshToken = "rotated-by-the-client"

    /// A fresh keychain in state A2, one user throughout: the plugin's stored-format golden (expired tokens,
    /// refresh token `fixture-refresh-token`) under its own key, as the client found it; and the client's
    /// default-session record holding the same session after the client's refresh rotated its refresh token.
    private func seedA2() throws -> A2Records {
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
        let stale = try RollbackMatrixBytes.goldenSession("session-userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(stale, pluginAccount, in: keychain)
        let client = try RollbackMatrixBytes.replacingRefreshToken(in: stale, with: clientRotatedRefreshToken)
        let written = try RollbackMatrixBytes.writeClientRecord(client, in: keychain, pools: pools)
        XCTAssertNotEqual(refreshToken(in: stale), refreshToken(in: client))
        XCTAssertEqual(userId(in: stale), userId(in: client))
        return A2Records(stale: stale, client: client, written: written)
    }

    private func userId(in payload: Data) -> String? {
        switch try? decoded(payload) {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            return signedInData.userId
        default:
            return nil
        }
    }

    private func decoded(_ payload: Data) throws -> AmplifyCredentials {
        try JSONDecoder().decode(AmplifyCredentials.self, from: payload)
    }

    private func refreshToken(in payload: Data) -> String? {
        switch try? decoded(payload) {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            return signedInData.cognitoUserPoolTokens.refreshToken
        default:
            return nil
        }
    }
}

/// Strings recorded from `@Sendable` mock closures.
private final class RecordedStrings: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [String?] = []

    var values: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func append(_ value: String?) {
        lock.lock()
        recorded.append(value)
        lock.unlock()
    }
}

private extension InMemoryKeychainItemStore {
    /// Deletes a fixture item, whether or not it is there.
    func removeIgnoringErrors(_ account: String) {
        try? remove(account)
    }
}
// swiftlint:enable file_length type_body_length
