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

/// The rollback matrix, the plugin's side, for the shared saved login: the Cognito
/// client's `.default` reads and writes this plugin's own record, so an app rolled back from a build with the
/// client to a build with only this plugin, or forward again, finds the newest login.
///
/// Each row alternates the plugin (its real credential store, or the whole plugin through `makePluginOverKeychain`) and
/// the client (its real record store, or real clients through `ClientOverKeychain`) over one in-memory keychain, seeded
/// with the plugin's frozen payloads. The client's half of each row is in `RollbackMatrixClientTests`, under the same
/// name. The columns are the plugin binaries a rollback lands on (`RollbackPluginBinary`): `.released`, a released
/// plugin (2.62.0), and `.current`, this plugin.
///
/// The two columns run identical code on every read, save, delete and refresh path: this plugin's credential store,
/// which touches only its own key, as 2.62.0's does. `.released` differs only in its view of the keychain
/// (`PluginBinaryKeychainView` refuses it any read of a client record, a guard on the emulation that 2.62.0 never
/// needs, since it never asks) and in the access-group transition rows, where it runs 2.62.0's service-wide
/// `_removeAll()`. So the columns are not double coverage of the other rows: `hiddenReadAccounts` and
/// `mutatedClientAccounts` are the evidence there. The released access-group migration
/// (`migrateKeychainItemsOfUserSession: true`) is not emulated.
///
/// The rows the rollback matrix's checklist requires, here and in `RollbackMatrixClientTests`:
/// 1. rotation rollback now signed in: `testMatrix_rotationRollback_isNowSignedIn`, with the roll-forward,
///    `testMatrix_rollForwardAfterAPluginRotation_resumesOnTheNewestToken`;
/// 2. an old-plugin sign-out seen by the client: `testMatrix_oldPluginSignOut_isSeenByTheClient`;
/// 3. a client sign-in seen by the plugin: `testMatrix_clientSignIn_isSeenByThePlugin`;
/// 4. the label dropped when the user changes: `testMatrix_labelIsDroppedWhenTheUserChanges`;
/// 5. a configuration change, then a plugin rollback, with no stale overwrite:
///    `testMatrix_configurationChangeThenPluginRollback_noStaleOverwrite`;
/// 6. an uncarried change deleting under `.default` but keeping under a named session:
///    `testMatrix_uncarriedChange_deletesUnderDefault_keepsUnderANamedSession`;
/// 7. old `$default` records ignored by listing: `testMatrix_oldDollarDefaultRecordsAreIgnoredByListing`;
/// 8. item attributes on the plugin key matching the plugin's: `KeychainAttributeParityTests`, plugin target only;
/// 9. a plugin build with the old configuration running its own carry or delete after the client wrote a newer
///    `authConfiguration`: `testMatrix_pluginBuildWithTheOldConfiguration_runsItsOwnRuleAfterTheClient`.
///
/// The other rollback rows are in `RollbackMatrixPluginTests+Rollback.swift` (mixed binaries at rest, named sessions
/// across a rollback, and a newer sidecar) and `RollbackMatrixPluginTests+SignOut.swift` (a signed-out
/// user never signed back in, a client sign-out read as signed out, G2, and the documented caveat of a purge after a
/// carry). The client's bytes decoded by the released types are in `KeychainAttributeParityTests`.
/// `Matrix07` names a row of the cell matrix (which keys the keychain holds) that still holds.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the `@Sendable` closures the
///   production API takes. `XCTestCase` is not `Sendable`, and each test runs alone.
final class RollbackMatrixPluginTests: XCTestCase, @unchecked Sendable {

    let authConfiguration = Defaults.makeDefaultAuthConfigData()
    let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: Defaults.userPoolId, identityPoolId: Defaults.identityPoolId)
    var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }
    /// A development build's `$default` session record, which nothing reads any more.
    var leftoverAccount: String { SessionRecordKey.account(for: .default, in: pools, kind: .session) }
    var sidecarAccount: String { SessionRecordKey.metaAccount(in: pools) }

    var keychain: InMemoryKeychain!
    var pluginKeychain: InMemoryPluginKeychainStore!

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

    /// The client's records, as this suite seeds them, are the client's frozen formats
    ///
    /// - Given: The plugin's frozen `userPoolAndIdentityPool` payload
    /// - When:
    ///    - The client's record store writes it for a named session, and for `.default`
    /// - Then:
    ///    - The named session's bytes are exactly the client's schema-1 envelope around the payload, under its own
    ///      account
    ///    - `.default`'s are the payload itself, verbatim, under the plugin's own account
    ///
    func testMatrixBytes_clientRecordsAreTheFrozenFormats() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        let work = try SessionID.named("work")

        let named = try RollbackMatrixBytes.writeClientRecord(payload, for: work, label: "Work", in: keychain, pools: pools)
        let shared = try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)

        let base64 = payload.base64EncodedString().replacingOccurrences(of: "/", with: "\\/")
        let expected = #"{"credentials":"\#(base64)","generation":1,"kind":"userPoolAndIdentityPool","label":"Work","#
            + #""lastWriteTimestamp":1790000000000,"schemaVersion":1,"userId":"fixture-sub","username":"fixture-user"}"#
        XCTAssertEqual(String(bytes: named, encoding: .utf8), expected)
        XCTAssertEqual(
            keychain.value(service: pluginKeychainService, account: SessionRecordKey.account(for: work, in: pools, kind: .session)),
            named
        )
        XCTAssertEqual(shared, payload)
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), payload)
        XCTAssertEqual(pluginAccount, "amplify.\(Defaults.userPoolId).\(Defaults.identityPoolId).session")
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: leftoverAccount))
    }

    // MARK: - Matrix 07: plugin key only

    /// Matrix 07 row "Plugin key only", both columns
    ///
    /// - Given: Only the plugin's record, as the plugin wrote it
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - Both are signed in with exactly that record, neither reads a client record, and nothing is written
    ///
    func testMatrix07_pluginKeyOnly_everyPluginIsSignedIn() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(payload, pluginAccount, in: keychain)

        for binary in RollbackPluginBinary.allCases {
            let store = makeStore(binary)

            XCTAssertEqual(try store.retrieveCredential(), try decoded(payload), "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), payload, "\(binary)")
        }
    }

    // MARK: - The shared saved login

    /// A client sign-in is seen by the plugin
    ///
    /// - Given: The client signs alice in on `.default`
    /// - When:
    ///    - Each plugin binary retrieves its credentials over the same keychain
    /// - Then:
    ///    - Each reads alice's credentials, equal after decoding, through the released plugin's view of the keychain,
    ///      reading no client record and writing nothing
    ///
    func testMatrix_clientSignIn_isSeenByThePlugin() throws {
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(alice, in: keychain, pools: pools)

        for binary in RollbackPluginBinary.allCases {
            XCTAssertEqual(try makeStore(binary).retrieveCredential(), try decoded(alice), "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
        }
    }

    /// A sign-out by a plugin build that deletes its record is seen by the client
    ///
    /// - Given: Alice signed in through the client, which holds the bytes it read
    /// - When:
    ///    - The plugin's store deletes its record, then the client commits a refresh over what it read
    /// - Then:
    ///    - The client's guarded write is discarded, and its re-read finds no record: `.default` is signed out, its
    ///      signed-out row keeping the last user from the sidecar; the record is never recreated
    ///
    func testMatrix_oldPluginSignOut_isSeenByTheClient() throws {
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(alice, in: keychain, pools: pools)
        let client = RollbackMatrixBytes.clientStore(in: keychain, pools: pools)
        guard case .record(let held) = try client.read(.default) else {
            return XCTFail("The client should read alice")
        }

        try makeStore(.released).deleteCredential()

        var refreshed = held.record
        refreshed.credentials = try RollbackMatrixBytes.replacingRefreshToken(in: alice, with: "rotated-by-the-client")
        XCTAssertEqual(try client.write(refreshed, for: .default, expecting: held.version), .discarded)
        XCTAssertEqual(
            try client.read(.default),
            .record(VersionedSessionRecord(record: .signedOut(label: nil, username: "fixture-user", userId: "fixture-sub"), version: nil))
        )
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
    }

    /// The label is bound to the user: dropped when the plugin signs another user in
    ///
    /// - Given: The client labels alice's `.default` "Work"
    /// - When:
    ///    - The plugin's store saves alice again, refreshed; then it saves bob
    /// - Then:
    ///    - With alice refreshed, the row keeps "Work"
    ///    - With bob, the row and a read are bob's with no label, and the client's next write rewrites the sidecar
    ///      for bob without a label
    ///
    func testMatrix_labelIsDroppedWhenTheUserChanges() throws {
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(alice, in: keychain, pools: pools)
        let client = RollbackMatrixBytes.clientStore(in: keychain, pools: pools)
        guard case .written = try client.setDefaultLabel("Work") else {
            return XCTFail("The label should be written")
        }

        let aliceRefreshed = try RollbackMatrixBytes.replacingRefreshToken(in: alice, with: "rotated-by-the-plugin")
        try makeStore(.released).saveCredential(decoded(aliceRefreshed))
        XCTAssertEqual(try client.storedSessions(), [
            StoredSession(sessionId: .default, label: "Work", username: "fixture-user", kind: .userPoolAndIdentityPool)
        ])

        let bob = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: SignedInData(
                signedInDate: Date(),
                signInMethod: .apiBased(.userSRP),
                cognitoUserPoolTokens: LongLivedCredentials.tokens(username: "bob", sub: "bob-sub")
            ),
            identityID: "bob-identity",
            credentials: LongLivedCredentials.awsCredentials()
        )
        try makeStore(.released).saveCredential(bob)

        XCTAssertEqual(try client.storedSessions(), [
            StoredSession(sessionId: .default, label: nil, username: "bob", kind: .userPoolAndIdentityPool)
        ])
        guard case .record(let held) = try client.read(.default) else {
            return XCTFail("The client should read bob")
        }
        XCTAssertNil(held.record.label)
        XCTAssertEqual(held.record.userId, "bob-sub")

        XCTAssertTrue(try client.write(held.record, for: .default, expecting: held.version).didCommit)
        let sidecar = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: sidecarAccount))
        guard case .meta(let meta) = DefaultSessionMeta.decode(sidecar) else {
            return XCTFail("The sidecar should be readable")
        }
        XCTAssertEqual(meta.userId, "bob-sub")
        XCTAssertEqual(meta.username, "bob")
        XCTAssertNil(meta.label)
    }

    /// A development build's `$default` records are ignored by listing, beside the plugin's own record
    ///
    /// - Given: A leftover `$default.session` holding bob and a `$default` namespace marker, and the plugin's
    ///   record for alice
    /// - When:
    ///    - The client lists its saved sessions, and each plugin binary retrieves its credentials
    /// - Then:
    ///    - The only row is alice's, the shared record's; each plugin reads alice; neither leftover is read or
    ///      written
    ///
    func testMatrix_oldDollarDefaultRecordsAreIgnoredByListing() throws {
        let bob = try SessionRecordEnvelope(
            generation: 1,
            lastWriteTimestamp: RollbackMatrixBytes.clientWriteTime,
            record: SessionRecord(label: "Bob's", username: "bob", userId: "bob-sub", kind: .userPoolOnly, credentials: Data("bob".utf8))
        ).encoded()
        try RollbackMatrixBytes.put(bob, leftoverAccount, in: keychain)
        let leftoverMarker = SessionRecordKey.markerAccount(for: .default, scope: SessionRecordStore.appMarkerScope)
        try RollbackMatrixBytes.put(Data(#"{"copies":[],"poolNamespace":"us-east-1_Other","schemaVersion":1}"#.utf8), leftoverMarker, in: keychain)
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(alice, pluginAccount, in: keychain)

        XCTAssertEqual(try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: .default, label: nil, username: "fixture-user", kind: .userPoolAndIdentityPool)
        ])
        for binary in RollbackPluginBinary.allCases {
            XCTAssertEqual(try makeStore(binary).retrieveCredential(), try decoded(alice), "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
        }
        XCTAssertFalse(keychain.mutatedAccounts.contains(leftoverAccount))
        XCTAssertFalse(keychain.mutatedAccounts.contains(leftoverMarker))
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: leftoverAccount), bob)
    }

    /// The client's purge deletes the shared record
    ///
    /// - Given: Alice signed in through the client, then purged through the client
    /// - When:
    ///    - Each plugin binary retrieves its credentials
    /// - Then:
    ///    - The record and the sidecar are gone, each plugin is signed out, and nothing is written
    ///
    func testMatrix_clientPurge_everyPluginIsSignedOut() throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)
        try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).purge(.default)
        keychain.resetMutations()
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: sidecarAccount))

        for binary in RollbackPluginBinary.allCases {
            XCTAssertThrowsError(try makeStore(binary).retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
        }
    }

    // MARK: - Configuration changes: `.default` follows the plugin's rule and records `authConfiguration`

    /// A configuration change, then a rollback to a plugin build: no stale overwrite
    ///
    /// - Given: The plugin ran with an identity-pool-only configuration A and stored a guest under A's account
    /// - When:
    ///    - The client's `.default` runs the rule under C (a user pool added beside the same identity pool), which
    ///      carries the guest, and alice signs in over it; then the plugin's store is built with C
    /// - Then:
    ///    - The plugin reads alice: `authConfiguration` is C, so its carry branch does not run again
    ///    - Negative control: with `authConfiguration` rewound to A (what a client that did not record it would leave),
    ///      the plugin copies the stale guest over alice
    ///
    func testMatrix_configurationChangeThenPluginRollback_noStaleOverwrite() throws {
        let identityPoolOnly = ConfigurationChangeCase.identityPool()
        let both = ConfigurationChangeCase.both()
        let guest = try RollbackMatrixBytes.pluginPayload("identityPoolOnly")
        try pluginStore(identityPoolOnly).saveCredential(decoded(guest))
        let client = clientStore(for: both)

        guard case .carried = try client.applyPluginConfigurationRule(current: both) else {
            return XCTFail("the client's rule should carry the guest to C")
        }
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try signIn(alice, through: client)

        XCTAssertEqual(try pluginStore(both).retrieveCredential(), try decoded(alice))

        try RollbackMatrixBytes.put(
            AWSCognitoAuthCredentialStore.encodeAuthConfiguration(identityPoolOnly),
            AWSCognitoAuthCredentialStore.authConfigurationAccount,
            in: keychain
        )
        XCTAssertEqual(try pluginStore(both).retrieveCredential(), try decoded(guest))
    }

    /// A change the plugin does not carry deletes `.default`'s login, and keeps a named session's
    ///
    /// - Given: `.default` and `.named("work")` both signed in through the client under user pool A
    /// - When:
    ///    - Both restore under user pool B; then both again under A
    /// - Then:
    ///    - Under B, A's plugin record is gone, while work's record under A is kept and not carried
    ///    - Back on A, `.default` is absent, its sidecar deleted with its record, and work is signed in; the plugin
    ///      under A finds no record
    ///
    func testMatrix_uncarriedChange_deletesUnderDefault_keepsUnderANamedSession() throws {
        let work = try SessionID.named("work")
        let configurationA = ConfigurationChangeCase.both()
        let configurationB = ConfigurationChangeCase.userPool(poolId: "us-east-1_PoolB")
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        let underA = clientStore(for: configurationA)
        _ = try underA.applyPluginConfigurationRule(current: configurationA)
        try signIn(alice, through: underA)
        try signIn(alice, for: work, through: underA)
        let workAccount = underA.sessionAccount(for: work)
        let workRecord = keychain.value(service: pluginKeychainService, account: workAccount)

        let underB = clientStore(for: configurationB)
        guard case .cleared = try underB.applyPluginConfigurationRule(current: configurationB) else {
            return XCTFail("a change of the user pool deletes the old record")
        }
        XCTAssertEqual(try underB.read(.default), .absent)
        XCTAssertEqual(try underB.readCarryingForward(work), .absent)
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: AWSCognitoAuthCredentialStore.sessionAccount(for: configurationA)))
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: workAccount), workRecord)

        _ = try underA.applyPluginConfigurationRule(current: configurationA)
        XCTAssertEqual(try underA.read(.default), .absent)
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: SessionRecordKey.metaAccount(in: PoolNamespace(configurationA))))
        guard case .record(let workBack) = try underA.readCarryingForward(work) else {
            return XCTFail("work should still be signed in under A")
        }
        XCTAssertEqual(workBack.record.credentials, alice)
        XCTAssertThrowsError(try pluginStore(configurationA).retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
    }

    /// A plugin build with the older configuration runs its own rule after the client recorded a newer one
    ///
    /// - Given: For each pair of the decision table, an older login saved by the plugin under the older configuration
    ///   A; the client's `.default` then ran the rule under the newer configuration C, alice signed in, and
    ///   `authConfiguration` is C
    /// - When:
    ///    - A plugin store is built with A over the same keychain
    /// - Then:
    ///    - It runs exactly its own rule from C to A: a carried change copies alice's record to A's key, so the newest
    ///      login wins; a deleting change deletes alice's record under C, and the plugin reads what A's key still holds
    ///      (for the reverse of an added user pool, the guest the client's earlier carry kept there)
    ///    - No pair writes an older copy over a newer login: C's account holds alice or nothing
    ///
    func testMatrix_pluginBuildWithTheOldConfiguration_runsItsOwnRuleAfterTheClient() throws {
        for row in ConfigurationChangeCase.table {
            guard let older = row.previous else {
                continue
            }
            let newer = row.current
            keychain = InMemoryKeychain()
            pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
            let olderLogin = older.getUserPoolConfiguration() == nil
                ? try RollbackMatrixBytes.pluginPayload("identityPoolOnly")
                : try RollbackMatrixBytes.replacingRefreshToken(
                    in: RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool"),
                    with: "refresh-older"
                )
            try pluginStore(older).saveCredential(decoded(olderLogin))
            let client = clientStore(for: newer)
            _ = try client.applyPluginConfigurationRule(current: newer)
            let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
            try signIn(alice, through: client)
            let olderAccount = AWSCognitoAuthCredentialStore.sessionAccount(for: older)
            let newerAccount = AWSCognitoAuthCredentialStore.sessionAccount(for: newer)
            let leftAtOlder = keychain.value(service: pluginKeychainService, account: olderAccount)

            let retrieved = try? pluginStore(older).retrieveCredential()

            switch AWSCognitoAuthCredentialStore.configurationChange(from: newer, to: older) {
            case .carry, .unchanged:
                XCTAssertEqual(retrieved, try decoded(alice), row.name)
            case .clear:
                XCTAssertNil(keychain.value(service: pluginKeychainService, account: newerAccount), row.name)
                XCTAssertEqual(retrieved, try leftAtOlder.map(decoded), row.name)
            }
            let atNewer = keychain.value(service: pluginKeychainService, account: newerAccount)
            XCTAssertTrue(atNewer == nil || (try? decoded(XCTUnwrap(atNewer))) == (try? decoded(alice)), row.name)
        }
    }

    // MARK: - Helpers

    /// Signs `payload`'s user in to `sessionId` through the client's store, over whatever it holds.
    func signIn(_ payload: Data, for sessionId: SessionID = .default, through store: SessionRecordStore) throws {
        let version: RecordVersion? = if case .record(let held) = try store.read(sessionId) { held.version } else { nil }
        let summary = PluginRecordSummary.peek(payload)
        let record = SessionRecord(label: nil, username: summary.username, userId: summary.userId, kind: summary.kind, credentials: payload)
        XCTAssertTrue(try store.write(record, for: sessionId, expecting: version).didCommit)
    }

    func makeStore(_ binary: RollbackPluginBinary) -> AWSCognitoAuthCredentialStore {
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            keychain: binary.keychainStore(over: pluginKeychain),
            logger: AmplifyEngineLogRouter()
        )
        // Construction records the configuration; only what the test does next is of interest.
        keychain.resetMutations()
        return store
    }
}
