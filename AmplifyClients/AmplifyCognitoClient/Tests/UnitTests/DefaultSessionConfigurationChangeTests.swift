//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFoundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default` follows the Auth plugin's configuration-change rule: it carries what the plugin carries, deletes what it deletes, writes the plugin's `authConfiguration`, and
/// revokes a deleted login of the same user pool with the previous app client ID. Named sessions keep their own rule.
///
/// Each test drives the client's real record store and core, with the live engine over scripted Cognito, and the
/// plugin's real credential store, `AWSCognitoAuthCredentialStore`, over one in-memory keychain.
final class DefaultSessionConfigurationChangeTests: XCTestCase {

    private var harness: ClientHarness!
    private var cognito: ScriptedCognito!
    private var revokers: PreviousConfigurationRevokers!
    private var sink: CategoryCapture!

    override func setUp() {
        harness = ClientHarness()
        cognito = ScriptedCognito()
        revokers = PreviousConfigurationRevokers()
        sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        AmplifyLogging.removeSink(sink)
        harness = nil
        cognito = nil
        revokers = nil
        sink = nil
    }

    // MARK: - authConfiguration

    /// - Given: nothing stored
    /// - When: a `.default` client restores; then the plugin's store is built with the same configuration
    /// - Then:
    ///    - `authConfiguration` holds what `encodeAuthConfiguration(AuthConfiguration(client:))` gives, equal after
    ///      decoding (`JSONEncoder` does not fix the order of the keys), and the plugin's store reads it as its own
    ///      configuration: it carries and deletes nothing, and records the same configuration
    func testFirstRestoreWritesThePluginsAuthConfiguration() async throws {
        let restored = await makeClient(ChangeConfigs.both).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        let recorded = try XCTUnwrap(harness.keychain.value(SessionRecordStore.pluginConfigurationAccount))
        let encoded = try AWSCognitoAuthCredentialStore.encodeAuthConfiguration(AuthConfiguration(client: ChangeConfigs.both))
        XCTAssertEqual(
            try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(recorded),
            try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(encoded)
        )
        XCTAssertEqual(try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(recorded), AuthConfiguration(client: ChangeConfigs.both))
        harness.keychain.resetLogs()
        pluginStore(ChangeConfigs.both)
        XCTAssertEqual(harness.keychain.removedAccounts, [])
        XCTAssertEqual(harness.keychain.writtenAccounts, [SessionRecordStore.pluginConfigurationAccount])
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    /// - Given: the plugin's record for alice, under the configuration the plugin recorded
    /// - When: a `.default` client restores under the same configuration
    /// - Then:
    ///    - nothing is written: not the record, and not `authConfiguration`, which already holds this configuration
    func testRestoreUnderTheRecordedConfigurationWritesNothing() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)

        let restored = await makeClient(ChangeConfigs.both).currentSessionState()

        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: the `authConfiguration` read fails with `errSecInteractionNotAllowed`, beside a record the change would
    ///   carry
    /// - When: a `.default` client restores; then the keychain recovers and it restores again
    /// - Then:
    ///    - the first restore is `unavailable(.locked)`, and nothing is written; the second carries the record and
    ///      records the configuration
    func testFailedConfigurationRead_failsTheRestoreAndWritesNothing() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        harness.keychain.failingReads(of: SessionRecordStore.pluginConfigurationAccount, with: errSecInteractionNotAllowed)
        let client = makeClient(ChangeConfigs.both)

        let locked = await client.currentSessionState()

        XCTAssertEqual(locked, .unavailable(.locked))
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        harness.keychain.clearFailures()
        let restored = await client.currentSessionState()
        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    /// - Given: a record the change would carry, whose read fails
    /// - When: a `.default` client restores
    /// - Then:
    ///    - the restore fails as storage unavailable, nothing is written, and `authConfiguration` still names the
    ///      previous configuration, so the next restore carries
    func testFailedReadOfTheRecordToCarry_writesNothingAndKeepsThePreviousConfiguration() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        harness.keychain.failingReads(of: account(ChangeConfigs.userPoolOnly), with: errSecInteractionNotAllowed)

        let state = await makeClient(ChangeConfigs.both).currentSessionState()

        XCTAssertEqual(state, .unavailable(.locked))
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.userPoolOnly))
    }

    // MARK: - The carried changes

    /// - Given: the plugin under an identity-pool-only configuration, holding a guest
    /// - When: a `.default` client restores with a user pool added, the same identity pool
    /// - Then:
    ///    - the guest's bytes are copied as they are to the new account, the old record is kept, and `.default` is the
    ///      same guest
    func testUserPoolAddedToIdentityPoolOnly_carriesTheGuestAsIs() async throws {
        let guest = try pluginSaves(ChangePayloads.guest(), under: ChangeConfigs.identityPoolOnly)

        let restored = await makeClient(ChangeConfigs.both).currentSessionState()

        XCTAssertEqual(restored, .guest)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), guest)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.identityPoolOnly)), guest)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    /// - Given: the plugin under a user-pool-only configuration, holding alice
    /// - When: a `.default` client restores with an identity pool added; then AWS credentials are asked for
    /// - Then:
    ///    - the carried bytes equal the old `userPoolOnly` ones, and the old record is kept
    ///    - the carried record is identity-pending: the first AWS-credentials call fetches the identity (`GetId`,
    ///      then `GetCredentialsForIdentity`, beside the refresh that runs it) and commits it to the shared record
    func testIdentityPoolAddedUnderTheSameUserPool_carriesTheBytesAndKeepsTheOld() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        let client = makeClient(ChangeConfigs.both)

        let restored = await client.currentSessionState()

        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), old)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), old)
        cognito.clearCalls()
        scriptRefresh(version: 2)
        scriptIdentityPool(identityId: "us-east-1:identity-new")
        let session = try await client.fetchAuthSession()
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:identity-new")
        XCTAssertEqual(cognito.operations.filter { $0 != "GetTokensFromRefreshToken" }, ["GetId", "GetCredentialsForIdentity"])
        guard case .userPoolAndIdentityPool(_, let identityId, _) = try AmplifyCredentials.decoded(XCTUnwrap(harness.keychain.value(account(ChangeConfigs.both)))) else {
            return XCTFail("the shared record should now hold the identity")
        }
        XCTAssertEqual(identityId, "us-east-1:identity-new")
    }

    /// The old identity ID goes along with a changed identity pool, as the plugin's bytes carry it.
    ///
    /// - Given: the plugin under both pools, holding alice with identity `X` of the old identity pool
    /// - When: a `.default` client restores with the identity pool changed; AWS credentials are asked for; then a
    ///   refresh is forced
    /// - Then:
    ///    - the carried bytes equal the old ones, identity `X` included
    ///    - the next AWS-credentials call returns `X` and the old pool's AWS credentials, with no Cognito call
    ///    - the forced refresh sends `X` to `GetCredentialsForIdentity`, with no `GetId`. That call names no identity
    ///      pool: Cognito answers for the pool `X` belongs to, the old one, so the scripted success, the old pool's
    ///      credentials, is what an old pool that still trusts the user pool returns. The refusal is
    ///      `testCarriedIdentityIDRefusedByCognito_getsAnIdentityOfTheNewPool`
    func testIdentityPoolChangedUnderTheSameUserPool_carriesTheOldIdentityID() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.both)
        let client = makeClient(ChangeConfigs.bothOtherIdentityPool)

        let restored = await client.currentSessionState()

        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.bothOtherIdentityPool)), old)
        cognito.clearCalls()
        let session = try await client.fetchAuthSession()
        XCTAssertEqual(try session.identityIdResult.get(), LiveEngineFixtures.identityId)
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, "AKID-v1")
        XCTAssertEqual(cognito.operations, [])

        scriptRefresh(version: 2)
        scriptIdentityPool(version: 2)
        _ = try await client.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertFalse(cognito.operations.contains("GetId"))
        XCTAssertEqual(
            cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).map(\.identityId),
            [LiveEngineFixtures.identityId]
        )
    }

    /// When Cognito refuses the carried identity ID with a refusal the engine retries (`ResourceNotFoundException`, as
    /// once the old identity pool is deleted, or `NotAuthorizedException` "Access to Identity … is forbidden"), the
    /// refresh recovers as the plugin's does: it asks the new identity pool for an identity of its own.
    ///
    /// - Given: alice's record carried from both pools to the same user pool with another identity pool, with identity
    ///   `X` of the old one
    /// - When: a refresh is forced; `GetCredentialsForIdentity` refuses `X` with `ResourceNotFoundException`, and the new
    ///   pool's `GetId` issues `Y`
    /// - Then:
    ///    - the calls are the refresh, `GetCredentialsForIdentity` for `X`, `GetId`, then `GetCredentialsForIdentity`
    ///      for `Y`; the session reports `Y` and its credentials, and the shared record holds `Y`
    func testCarriedIdentityIDRefusedByCognito_getsAnIdentityOfTheNewPool() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        let client = makeClient(ChangeConfigs.bothOtherIdentityPool)
        _ = await client.currentSessionState()
        cognito.clearCalls()
        scriptRefresh(version: 2)
        let newIdentity = "us-east-1:identity-new-pool"
        cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: newIdentity) }
        cognito.always("GetCredentialsForIdentity") { (input: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            guard input.identityId == newIdentity else {
                throw AWSCognitoIdentity.ResourceNotFoundException(message: "Identity '\(input.identityId ?? "")' not found.")
            }
            return GetCredentialsForIdentityOutput(credentials: LiveEngineFixtures.awsCredentials(version: 3), identityId: input.identityId)
        }

        let session = try await client.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(cognito.operations, ["GetTokensFromRefreshToken", "GetCredentialsForIdentity", "GetId", "GetCredentialsForIdentity"])
        XCTAssertEqual(
            cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).map(\.identityId),
            [LiveEngineFixtures.identityId, newIdentity]
        )
        XCTAssertEqual(try session.identityIdResult.get(), newIdentity)
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, "AKID-v3")
        guard case .userPoolAndIdentityPool(_, let stored, _) = try AmplifyCredentials.decoded(XCTUnwrap(harness.keychain.value(account(ChangeConfigs.bothOtherIdentityPool)))) else {
            return XCTFail("the shared record should hold the new identity")
        }
        XCTAssertEqual(stored, newIdentity)
    }

    /// The contrast to `.default`'s carried identity ID: a named session carries user pool tokens only (its own rule).
    ///
    /// - Given: `.named("work")` signed in under both pools, with the old identity pool's identity
    /// - When: it restores with the identity pool changed, and AWS credentials are asked for
    /// - Then:
    ///    - the new identity pool issues its own identity: `GetId`, then `GetCredentialsForIdentity`, beside the refresh
    ///      that runs them
    func testNamedSessionUnderAChangedIdentityPool_getsANewIdentity() async throws {
        let work = ClientFixtures.id("work")
        var named: AmplifyCognitoClient? = makeClient(ChangeConfigs.both, work)
        scriptSRP("alice")
        scriptIdentityPool(identityId: "us-east-1:identity-work")
        _ = try await named?.signIn(username: "alice", password: "password")
        named = nil
        await harness.waitForBaseline()
        let namedThere = makeClient(ChangeConfigs.bothOtherIdentityPool, work)
        cognito.clearCalls()
        scriptRefresh(version: 2)
        scriptIdentityPool(identityId: "us-east-1:identity-work-2")

        let namedSession = try await namedThere.fetchAuthSession()

        XCTAssertEqual(try namedSession.identityIdResult.get(), "us-east-1:identity-work-2")
        XCTAssertEqual(cognito.operations.filter { $0 != "GetTokensFromRefreshToken" }, ["GetId", "GetCredentialsForIdentity"])
    }

    /// - Given: the plugin under both pools, holding alice
    /// - When: a `.default` client restores with the identity pool removed
    /// - Then:
    ///    - the bytes are copied as they are, the old record is kept, and `.default` is alice
    func testIdentityPoolRemovedUnderTheSameUserPool_carries() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.both)

        let restored = await makeClient(ChangeConfigs.userPoolOnly).currentSessionState()

        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), old)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), old)
    }

    /// - Given: alice's `.default` labelled "Work" under a user-pool-only configuration
    /// - When: a `.default` client restores with an identity pool added
    /// - Then:
    ///    - the carried record keeps its label: the sidecar went with it, for the same user
    func testCarriedRecordKeepsItsLabel() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        var first: AmplifyCognitoClient? = makeClient(ChangeConfigs.userPoolOnly)
        try await first?.setSessionLabel("Work")
        first = nil
        await harness.waitForBaseline()

        _ = await makeClient(ChangeConfigs.both).currentSessionState()

        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Work")
    }

    /// The record the rule copies is read again once if found absent, where the keychain's `set` deletes and re-adds,
    /// as the shared record is.
    ///
    /// - Given: the re-read on; the previous configuration's record, which another process's delete-then-add makes
    ///   absent for the first read only
    /// - When: the rule runs for a carrying change
    /// - Then:
    ///    - the record is carried, after two reads of it; with the re-read off, nothing is carried
    func testTheCarrySourceIsReReadOnceWhenAbsent() throws {
        let keychain = TestKeychain()
        let payload = try ChangePayloads.guest()
        let previous = AuthConfiguration(client: ChangeConfigs.identityPoolOnly)
        let current = AuthConfiguration(client: ChangeConfigs.both)
        let source = AWSCognitoAuthCredentialStore.sessionAccount(for: previous)
        let namespace = SessionStorageNamespace(pools: ChangeConfigs.both.poolNamespace, accessGroup: nil)
        for rereads in [true, false] {
            keychain.recordPluginConfiguration(previous)
            keychain.onceAfterReading(source) { keychain.put(payload, source) }
            let store = keychain.recordStore(for: namespace, rereadsAbsentSharedRecord: rereads)

            let outcome = try store.applyPluginConfigurationRule(current: current)

            XCTAssertEqual(outcome, rereads ? .carried : .unchanged, "\(rereads)")
            XCTAssertEqual(keychain.value(account(ChangeConfigs.both)), rereads ? payload : nil, "\(rereads)")
            try? keychain.itemStore(service: SessionRecordStore.unsharedService).remove(source)
            try? keychain.itemStore(service: SessionRecordStore.unsharedService).remove(account(ChangeConfigs.both))
            keychain.resetLogs()
        }
    }

    // MARK: - The deleted changes    // MARK: - The deleted changes

    /// - Given: the plugin under user pool A, holding alice, labelled through the client
    /// - When: a `.default` client restores under user pool B
    /// - Then:
    ///    - the old record is deleted with its sidecar, `.default` is signed out, and nothing is revoked: another
    ///      user pool's login stays valid until it expires
    ///    - back under A, no signed-out row is listed for a login alice never signed out of
    func testUserPoolChanged_deletesTheOldRecordAndDoesNotRevoke() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.both)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        let oldSidecar = SessionRecordKey.metaAccount(in: ChangeConfigs.both.poolNamespace)
        XCTAssertNotNil(harness.keychain.value(oldSidecar))
        cognito.clearCalls()

        var restoredClient: AmplifyCognitoClient? = makeClient(ChangeConfigs.otherUserPool)
        let restored = await restoredClient?.currentSessionState()
        restoredClient = nil
        await harness.waitForBaseline()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNil(harness.keychain.value(oldSidecar))
        let rowsBack = try await listed(ChangeConfigs.both, includingSignedOut: true)
        XCTAssertEqual(rowsBack, [])
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
        XCTAssertEqual(cognito.operations, [])
    }

    /// The revoke uses the previous configuration's app client ID: `RevokeToken` refuses another client's token.
    ///
    /// - Given: the plugin under a user-pool-only configuration with app client 1, holding alice
    /// - When: a `.default` client restores under the same user pool with app client 2 and an identity pool added
    /// - Then:
    ///    - the old record is deleted, and `.default` is signed out
    ///    - one `RevokeToken` is sent, with alice's refresh token and app client 1; nothing is logged
    func testAppClientChangedWithAnIdentityPoolAdded_deletesAndRevokesWithTheOldClientID() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        cognito.clearCalls()
        cognito.once("RevokeToken") { (_: RevokeTokenInput) in RevokeTokenOutput() }

        let restored = await makeClient(ChangeConfigs.otherClientBoth).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        await waitUntil("the revoke is sent") { self.cognito.operations == ["RevokeToken"] }
        let revoke = try XCTUnwrap(cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first)
        XCTAssertEqual(revoke.clientId, "app-client-1")
        XCTAssertEqual(revoke.token, "refresh-alice-v1")
        XCTAssertEqual(revokers.configurations, [AuthConfiguration(client: ChangeConfigs.userPoolOnly)])
        try await settleRevokes()
        XCTAssertEqual(sink.lines(in: [ClientLog.category(ClientLog.defaultSession)]), [])
    }

    /// - Given: the same change, with `RevokeToken` failing
    /// - When: a `.default` client restores
    /// - Then:
    ///    - the old record is still deleted and `.default` signed out; the revoke is tried once, and one warning is
    ///      logged under `AmplifyCognitoClient.DefaultSession`, naming no one
    func testAFailedRevoke_logsOneWarningAndTheLoginStaysDeleted() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        cognito.clearCalls()
        cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in
            throw AWSCognitoIdentityProvider.UnsupportedOperationException(message: "Revocation is not enabled for this app client")
        }

        let restored = await makeClient(ChangeConfigs.otherClientBoth).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        let category = ClientLog.category(ClientLog.defaultSession)
        await waitUntil("the warning is logged") { !self.sink.lines(in: [category]).isEmpty }
        XCTAssertEqual(sink.lines(in: [category]), [
            "A login deleted by a configuration change could not be revoked; its refresh token stays valid until it expires."
        ])
        XCTAssertEqual(cognito.operations, ["RevokeToken"])
    }

    /// - Given: a guest under an identity-pool-only configuration
    /// - When: a `.default` client restores under another identity pool
    /// - Then:
    ///    - the guest's record is deleted, and nothing is revoked: it holds no user pool tokens
    func testDeletedGuest_isNotRevoked() async throws {
        try pluginSaves(ChangePayloads.guest(), under: ChangeConfigs.identityPoolOnly)

        let restored = await makeClient(ChangeConfigs.otherIdentityPoolOnly).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.identityPoolOnly)))
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
    }

    // MARK: - The app client alone

    /// - Given: the plugin under both pools with app client 1, holding alice
    /// - When: a `.default` client restores with app client 2 and the same pools; then a refresh is forced, and
    ///   Cognito refuses the old client's refresh token
    /// - Then:
    ///    - the record stays under the same key, byte-identical, and nothing is deleted or revoked
    ///    - the refresh fails with `sessionExpired`, as the plugin's does
    func testAppClientChangedWithTheSamePools_keepsTheRecordInPlace() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.both)
        let client = makeClient(ChangeConfigs.otherClientBothSamePools)

        let restored = await client.currentSessionState()

        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), old)
        XCTAssertEqual(harness.keychain.removedAccounts, [])
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.otherClientBothSamePools))
        cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid Refresh Token")
        }
        let refreshed = try await client.fetchAuthSession(options: .init(forceRefresh: true))
        guard case .failure(let error) = refreshed.userPoolTokensResult, case .sessionExpired = error else {
            return XCTFail("expected sessionExpired, got \(refreshed.userPoolTokensResult)")
        }
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
    }

    // MARK: - Gen1 and Gen2 alternating

    /// A plugin built from a Gen1 configuration records a custom endpoint and a Pinpoint app ID the client's Gen2
    /// configuration lacks. Alternating the two takes the carry branch onto the same key, which changes nothing.
    ///
    /// - Given: the plugin, with the same pools and app client but a Gen1 configuration, holding alice
    /// - When: a `.default` client restores; then the Gen1 plugin starts again; then the client again
    /// - Then:
    ///    - every time alice's record is byte-identical and read as alice; the client writes only `authConfiguration`,
    ///      and each records its own configuration
    func testGen1PluginConfigurationThenClient_selfCopiesHarmlessly() async throws {
        let gen1 = ChangeConfigs.gen1(of: ChangeConfigs.both)
        XCTAssertNotEqual(gen1, AuthConfiguration(client: ChangeConfigs.both))
        let payload = try await signedInPayload("alice", under: ChangeConfigs.both)
        let record = try pluginSaves(payload, under: gen1)

        var client: AmplifyCognitoClient? = makeClient(ChangeConfigs.both)
        let first = await client?.currentSessionState()
        client = nil
        await harness.waitForBaseline()

        XCTAssertEqual(first, .signedIn(alice))
        XCTAssertEqual(harness.keychain.writtenAccounts, [SessionRecordStore.pluginConfigurationAccount])
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), record)
        _ = AWSCognitoAuthCredentialStore(authConfiguration: gen1, keychain: pluginKeychain, logger: DiscardingEngineLogger())
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), gen1)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), record)
        let again = await makeClient(ChangeConfigs.both).currentSessionState()
        XCTAssertEqual(again, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), record)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    // MARK: - Listing and the static calls

    /// - Given: alice's labelled record under a user-pool-only configuration, and no restore since an identity pool
    ///   was added
    /// - When: the saved sessions are listed under the new configuration
    /// - Then:
    ///    - `.default` is listed as it will be carried: alice, with her label; nothing is written
    func testListingBeforeRestore_afterACarryingChange_listsTheRow() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.userPoolOnly)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        harness.keychain.resetLogs()

        let rows = try await listed(ChangeConfigs.both)

        XCTAssertEqual(rows, [StoredSession(sessionId: .default, label: "Work", username: "alice", kind: .userPoolOnly)])
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: alice's record under user pool A, and no restore since the user pool changed
    /// - When: the saved sessions are listed under user pool B
    /// - Then:
    ///    - no `.default` row is listed, and nothing is written or deleted
    func testListingBeforeRestore_afterAClearingChange_listsNoRow() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        harness.keychain.resetLogs()

        let rows = try await listed(ChangeConfigs.otherUserPool, includingSignedOut: true)

        XCTAssertEqual(rows, [])
        XCTAssertFalse(harness.keychain.hasMutations)
    }

    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: `signOutStoredSession(.default)` runs under the new configuration
    /// - Then:
    ///    - the rule runs first: the record is carried, then revoked and signed out under the new account
    ///    - the old record is kept, as the plugin keeps it; `authConfiguration` is the new configuration
    func testStaticSignOutAfterAChange_appliesTheRuleFirst() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [old])
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), old)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    /// A static call never clears the app's login: it may be made with a configuration other than the app's.
    ///
    /// - Given: alice's record under the app's configuration (user pool A), recorded as the plugin's last
    /// - When: `purgeStoredSession(.default)`, then `signOutStoredSession(.default)`, run under user pool B
    /// - Then:
    ///    - neither deletes or revokes alice's record, or changes `authConfiguration`; the next restore under B still
    ///      deletes it
    func testStaticCallsUnderAClearingChange_leaveTheAppsLoginAlone() async throws {
        let alice = try await pluginSignsIn("alice", under: ChangeConfigs.both)

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.otherUserPool,
            accessGroup: nil,
            dependencies: dependencies
        )
        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.otherUserPool,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), alice)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
        let restored = await makeClient(ChangeConfigs.otherUserPool).currentSessionState()
        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
    }

    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: `purgeStoredSession(.default)` runs under the new configuration
    /// - Then:
    ///    - the rule carries first, so the purge deletes the carried record; the old record is kept, as the plugin keeps
    ///      it, and `authConfiguration` is the new configuration
    func testStaticPurgeAfterACarryingChange_carriesFirst() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), old)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// A hosted-UI sign-in that must return a user of no other session counts `.default`'s login as its restore will
    /// read it, before `.default` is restored (the plugin's rule would carry it).
    ///
    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: a named session asks for its `.distinctFromOtherSessions` policy under the new configuration
    /// - Then:
    ///    - alice is excluded, held by `.default`; nothing is written
    func testDistinctFromOtherSessions_countsAPendingDefaultCarry() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        harness.keychain.resetLogs()
        let work = makeClient(ChangeConfigs.both, ClientFixtures.id("work"))

        let (policy, holders) = try await work.core.identityPolicy(for: .distinctFromOtherSessions)

        XCTAssertEqual(policy, EngineIdentityPolicy(excludedSubjects: ["sub-alice"]))
        XCTAssertEqual(holders, ["sub-alice": .default])
        XCTAssertEqual(harness.keychain.writtenAccounts.filter { !$0.hasPrefix("amplify.1.") }, [])
    }
    #endif

    // MARK: - Named sessions

    /// - Given: `.default` and `.named("work")` both signed in under user pool A
    /// - When: both restore under user pool B
    /// - Then:
    ///    - `.default`'s record is deleted; work's record is kept, and work is signed out under B only
    func testNamedSessionUnderTheSameChange_keepsTheOldRecord() async throws {
        let work = ClientFixtures.id("work")
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        var named: AmplifyCognitoClient? = makeClient(ChangeConfigs.both, work)
        scriptSRP("bob")
        scriptIdentityPool()
        _ = try await named?.signIn(username: "bob", password: "password")
        named = nil
        await harness.waitForBaseline()
        let workAccount = SessionRecordKey.account(for: work, in: ChangeConfigs.both.poolNamespace, kind: .session)
        let workRecord = harness.keychain.value(workAccount)

        let defaultThere = await makeClient(ChangeConfigs.otherUserPool).currentSessionState()
        let workThere = await makeClient(ChangeConfigs.otherUserPool, work).currentSessionState()

        XCTAssertEqual(defaultThere, .signedOut)
        XCTAssertEqual(workThere, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNotNil(workRecord)
        XCTAssertEqual(harness.keychain.value(workAccount), workRecord)
    }

    // MARK: - Parity with the plugin

    /// The parity table: the client's rule against the plugin's, on the same inputs.
    ///
    /// - Given: for each pair of configurations, and each seed (a record under the previous account only; under both
    ///   accounts; under neither), two keychains seeded alike
    /// - When: the plugin's store is built with the current configuration over one, and the client's `.default` rule
    ///   runs over the other
    /// - Then:
    ///    - the plugin's items (`amplify.<ns>.session` and `authConfiguration`) are identical in both, by bytes for the
    ///      records and by value for the configuration
    func testParityTable_clientAgainstThePlugin() throws {
        for pair in ChangeConfigs.pairs {
            for seed in ParitySeed.allCases {
                let name = "\(pair.name), \(seed)"
                let pluginSide = TestKeychain()
                let clientSide = TestKeychain()
                for keychain in [pluginSide, clientSide] {
                    seed.apply(previous: pair.previous, current: pair.current, to: keychain)
                }

                _ = AWSCognitoAuthCredentialStore(
                    authConfiguration: pair.current,
                    keychain: pluginSide.itemStore(service: SessionRecordStore.unsharedService),
                    logger: DiscardingEngineLogger()
                )
                let store = clientSide.recordStore(for: SessionStorageNamespace(pools: PoolNamespace(pair.current), accessGroup: nil))
                _ = try store.applyPluginConfigurationRule(current: pair.current)

                XCTAssertEqual(Self.pluginItems(clientSide), Self.pluginItems(pluginSide), name)
                XCTAssertEqual(clientSide.recordedPluginConfiguration(), pluginSide.recordedPluginConfiguration(), name)
                XCTAssertEqual(clientSide.recordedPluginConfiguration(), pair.current, name)
            }
        }
    }

    /// The plugin's store and the client, over one keychain, through each configuration change.
    ///
    /// - Given: one keychain; a guest saved by the plugin under an identity-pool-only configuration, then alice signed
    ///   in by the plugin once a user pool is added
    /// - When: for each configuration of a run of changes (each carried change, the app client alone, and the deleted
    ///   ones), first the plugin then the client starts under it; and, over a second keychain, first the client then
    ///   the plugin
    /// - Then:
    ///    - after each step both see the same login: the plugin's `retrieveCredential()` and the client's `.default`
    ///      hold the same credentials, or both none
    ///    - both orders leave the plugin's items identical
    func testSharedKeychain_pluginAndClientSeeIdenticalState_throughEachChange() async throws {
        let pluginFirst = TestKeychain()
        let clientFirst = TestKeychain()
        let alice = try await signedInPayload("alice", under: ChangeConfigs.both)
        for keychain in [pluginFirst, clientFirst] {
            let store = AWSCognitoAuthCredentialStore(
                authConfiguration: AuthConfiguration(client: ChangeConfigs.identityPoolOnly),
                keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
                logger: DiscardingEngineLogger()
            )
            try store.saveCredential(AmplifyCredentials.decoded(ChangePayloads.guest()))
        }

        for (step, configuration) in ChangeConfigs.run.enumerated() {
            let name = "step \(step): \(configuration.poolNamespace.keyComponent), \(configuration.userPool?.appClientId ?? "-")"
            let pluginSeesFirst = try startPlugin(configuration, over: pluginFirst)
            let clientSeesSecond = try startClient(configuration, over: pluginFirst)
            let clientSeesFirst = try startClient(configuration, over: clientFirst)
            let pluginSeesSecond = try startPlugin(configuration, over: clientFirst)

            XCTAssertEqual(clientSeesSecond, pluginSeesFirst, name)
            XCTAssertEqual(clientSeesFirst, pluginSeesSecond, name)
            XCTAssertEqual(pluginSeesFirst, pluginSeesSecond, name)
            XCTAssertEqual(Self.pluginItems(pluginFirst), Self.pluginItems(clientFirst), name)
            XCTAssertEqual(pluginFirst.recordedPluginConfiguration(), clientFirst.recordedPluginConfiguration(), name)

            if step == 1 {
                // Alice signs in through the plugin once the user pool is added.
                for keychain in [pluginFirst, clientFirst] {
                    let store = AWSCognitoAuthCredentialStore(
                        authConfiguration: AuthConfiguration(client: configuration),
                        keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
                        logger: DiscardingEngineLogger()
                    )
                    try store.saveCredential(AmplifyCredentials.decoded(alice))
                }
            }
        }
    }

    // MARK: - Helpers

    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    private var pluginKeychain: any KeychainItemStoreBehavior {
        harness.keychain.itemStore(service: SessionRecordStore.unsharedService)
    }

    private func account(_ configuration: AuthClientConfiguration) -> String {
        SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
    }

    /// The plugin's credential store, built with `configuration` over the harness's keychain: it runs its own rule.
    @discardableResult
    private func pluginStore(_ configuration: AuthClientConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(authConfiguration: AuthConfiguration(client: configuration), keychain: pluginKeychain, logger: DiscardingEngineLogger())
    }

    /// The plugin, built with `configuration`, saves `payload`; returns the bytes it stored. The logs are cleared.
    @discardableResult
    private func pluginSaves(_ payload: Data, under configuration: AuthClientConfiguration) throws -> Data {
        try pluginSaves(payload, under: AuthConfiguration(client: configuration))
    }

    @discardableResult
    private func pluginSaves(_ payload: Data, under configuration: AuthConfiguration) throws -> Data {
        let store = AWSCognitoAuthCredentialStore(authConfiguration: configuration, keychain: pluginKeychain, logger: DiscardingEngineLogger())
        try store.saveCredential(AmplifyCredentials.decoded(payload))
        harness.keychain.resetLogs()
        return try XCTUnwrap(harness.keychain.value(AWSCognitoAuthCredentialStore.sessionAccount(for: configuration)))
    }

    /// `username` signed in through the live engine under `configuration`, then saved by the plugin built with it.
    @discardableResult
    private func pluginSignsIn(_ username: String, under configuration: AuthClientConfiguration) async throws -> Data {
        try await pluginSaves(signedInPayload(username, under: configuration), under: configuration)
    }

    private func signedInPayload(_ username: String, under configuration: AuthClientConfiguration) async throws -> Data {
        scriptSRP(username)
        if configuration.identityPool != nil {
            scriptIdentityPool()
        }
        let engine = try Self.liveEngine(configuration, keychain: harness.keychain, cognito: cognito)
        guard case .done(let payload) = try await engine.signIn(.srp(username), current: nil) else {
            throw FixtureError(description: "the scripted sign-in did not finish")
        }
        cognito.clearCalls()
        return payload
    }

    /// The plugin started with `configuration` over `keychain`: what it then retrieves.
    private func startPlugin(_ configuration: AuthClientConfiguration, over keychain: TestKeychain) throws -> AmplifyCredentials? {
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: configuration),
            keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
            logger: DiscardingEngineLogger()
        )
        do {
            return try store.retrieveCredential()
        } catch EngineCredentialStoreError.itemNotFound {
            return nil
        }
    }

    /// The client's `.default` started with `configuration` over `keychain`: the rule, then the read.
    private func startClient(_ configuration: AuthClientConfiguration, over keychain: TestKeychain) throws -> AmplifyCredentials? {
        let store = keychain.recordStore(for: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        _ = try store.applyPluginConfigurationRule(current: AuthConfiguration(client: configuration))
        guard case .record(let stored) = try store.read(.default), let credentials = stored.record.credentials else {
            return nil
        }
        return try AmplifyCredentials.decoded(credentials)
    }

    /// The plugin's own items in `keychain`'s plugin service, by account: every item outside the client's
    /// `amplify.1.` family, `authConfiguration` aside, which is compared decoded.
    private static func pluginItems(_ keychain: TestKeychain) -> [String: PluginItem] {
        let store = keychain.itemStore(service: SessionRecordStore.unsharedService)
        let accounts = (try? store.allAccounts()) ?? []
        return Dictionary(uniqueKeysWithValues: accounts
            .filter { !$0.hasPrefix("amplify.1.") && $0 != SessionRecordStore.pluginConfigurationAccount }
            .compactMap { account in keychain.value(account).map { (account, PluginItem($0)) } })
    }

    private func listed(_ configuration: AuthClientConfiguration, includingSignedOut: Bool = false) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: configuration,
            accessGroup: nil,
            includingSignedOut: includingSignedOut,
            dependencies: dependencies
        )
    }

    /// Lets any revoke a restore started run: none is awaited by the restore.
    private func settleRevokes() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: The client

    private func makeClient(_ configuration: AuthClientConfiguration, _ sessionId: SessionID = .default) -> AmplifyCognitoClient {
        do {
            return try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId), dependencies: dependencies)
        } catch {
            preconditionFailure("the client could not be built: \(error)")
        }
    }

    /// The harness's dependencies, with the live engine over scripted Cognito for each session's configuration, and
    /// a previous configuration's revoker over the same scripted Cognito, recording the configuration it was built for.
    private var dependencies: SessionCoreDependencies {
        let base = harness.dependencies
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { [keychain = harness.keychain, cognito = cognito!] context in
                try Self.liveEngine(context.configuration, keychain: keychain, cognito: cognito)
            },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        let cognito = cognito!
        let revokers = revokers!
        dependencies.makePreviousConfigurationRevoker = { previous in
            revokers.record(previous)
            // The real revoker's resources for the previous configuration, with scripted Cognito underneath.
            do {
                return try LiveSessionRevoker(resources: LiveSessionRevoker.resources(
                    previous: previous,
                    clients: CognitoServiceClients(previous: previous),
                    services: EngineServices(userPool: ScriptedUserPool(cognito: cognito), identity: nil)
                ))
            } catch {
                preconditionFailure("the revoker could not be built: \(error)")
            }
        }
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = base.sheetLock
        #endif
        return dependencies
    }

    private static func liveEngine(
        _ configuration: AuthClientConfiguration,
        keychain: TestKeychain,
        cognito: ScriptedCognito
    ) throws -> LiveSessionEngine {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil)
        return try LiveSessionEngine(resources: EngineResources(
            authConfiguration: AuthConfiguration(client: configuration),
            clients: CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil),
            devices: DeviceRecordIO(store: keychain.deviceStore(for: namespace)),
            analytics: LazyUserPoolAnalytics(
                pinpointAppId: nil,
                keychain: keychain.itemStore(service: LazyUserPoolAnalytics.pinpointContextService)
            ),
            services: EngineServices(
                userPool: configuration.userPool == nil ? nil : ScriptedUserPool(cognito: cognito),
                identity: configuration.identityPool == nil ? nil : ScriptedIdentity(cognito: cognito)
            ),
            makeAdvancedSecurity: FixedDeviceASF.factory
        ))
    }

    // MARK: Scripts

    private func scriptSRP(_ username: String = "alice") {
        cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier(username) }
        cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn(username) }
    }

    private func scriptIdentityPool(identityId: String = LiveEngineFixtures.identityId, version: Int = 1) {
        cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: identityId) }
        cognito.always("GetCredentialsForIdentity") { (input: GetCredentialsForIdentityInput) in
            GetCredentialsForIdentityOutput(credentials: LiveEngineFixtures.awsCredentials(version: version), identityId: input.identityId)
        }
    }

    private func scriptRefresh(_ username: String = "alice", version: Int) {
        cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: version))
        }
    }
}

// MARK: - Fixtures

/// A plugin item as compared across two keychains: a saved login by its decoded credentials, since two plugin
/// builds may encode the same credentials with their keys in another order; anything else by its bytes.
private enum PluginItem: Equatable {
    case credentials(AmplifyCredentials)
    case bytes(Data)

    init(_ data: Data) {
        if let credentials = try? AmplifyCredentials.decoded(data) {
            self = .credentials(credentials)
        } else {
            self = .bytes(data)
        }
    }
}

/// What a parity row's two keychains start with.
private enum ParitySeed: CaseIterable, CustomStringConvertible {
    /// A record under the previous configuration's account only.
    case previousOnly
    /// A record under each account: the current one's is replaced by a carry.
    case both
    /// No record: nothing is carried or deleted.
    case neither

    var description: String {
        switch self {
        case .previousOnly: return "a record under the previous account"
        case .both: return "a record under each account"
        case .neither: return "no record"
        }
    }

    func apply(previous: AuthConfiguration?, current: AuthConfiguration, to keychain: TestKeychain) {
        if let previous {
            keychain.recordPluginConfiguration(previous)
            if self != .neither {
                keychain.put(Data("previous login".utf8), AWSCognitoAuthCredentialStore.sessionAccount(for: previous))
            }
        }
        if self == .both, AWSCognitoAuthCredentialStore.sessionAccount(for: current) != previous.map(AWSCognitoAuthCredentialStore.sessionAccount) {
            keychain.put(Data("current login".utf8), AWSCognitoAuthCredentialStore.sessionAccount(for: current))
        }
    }
}

/// The configurations each previous configuration's revoker was built for, in order.
private final class PreviousConfigurationRevokers: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [AuthConfiguration] = []

    var configurations: [AuthConfiguration] {
        lock.withLock { recorded }
    }

    func record(_ configuration: AuthConfiguration) {
        lock.withLock { recorded.append(configuration) }
    }
}
