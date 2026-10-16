//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
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

    var harness: ClientHarness!
    var cognito: ScriptedCognito!
    var revokers: PreviousConfigurationRevokers!
    var sink: CategoryCapture!
    let alice = AuthClientUser(username: "alice", userId: "sub-alice")

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
        let carried = try XCTUnwrap(harness.keychain.value(account(ChangeConfigs.both)))
        guard case .userPoolAndIdentityPool(_, let identityId, _) = try AmplifyCredentials.decoded(carried) else {
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
        let carried = try XCTUnwrap(harness.keychain.value(account(ChangeConfigs.bothOtherIdentityPool)))
        guard case .userPoolAndIdentityPool(_, let stored, _) = try AmplifyCredentials.decoded(carried) else {
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

            XCTAssertEqual(outcome, rereads ? .carried(fromAccount: source, bytes: payload) : .unchanged, "\(rereads)")
            XCTAssertEqual(keychain.value(account(ChangeConfigs.both)), rereads ? payload : nil, "\(rereads)")
            try? keychain.itemStore(service: SessionRecordStore.unsharedService).remove(source)
            try? keychain.itemStore(service: SessionRecordStore.unsharedService).remove(account(ChangeConfigs.both))
            keychain.resetLogs()
        }
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
}
