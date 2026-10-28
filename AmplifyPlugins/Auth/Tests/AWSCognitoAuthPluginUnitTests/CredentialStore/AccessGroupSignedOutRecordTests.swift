//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(AmplifyExperimental) import AmplifyFoundation
import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// Under an access group, every plugin path that ends a login saves the signed-out record, `{"noCredentials":{}}`, in
/// the shared service instead of deleting the session record: sign-out, local and global, clearing the federation to
/// the identity pool, and the local sign-out after a deleted user. So does one over a record that is already signed
/// out. The record then stops an app extension's first access-group migration, as a login does, so the extension's
/// stale login is never moved in over the user who signed out. A guest's sign-out still deletes the guest's record,
/// and a sign-out with nothing saved writes nothing, so neither stops a login's migration. Without an access group
/// the record is still deleted.
///
/// The plugin runs its real credential store, through its test seam, over an in-memory keychain shared with the
/// extension and with the Cognito client's `.default` session. Only the Cognito service calls are mocked.
final class AccessGroupSignedOutRecordTests: XCTestCase, @unchecked Sendable {

    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroup = "group.acme"

    /// Exactly what the Cognito client's `.default` saves on sign-out.
    private let signedOutRecord = Data(#"{"noCredentials":{}}"#.utf8)

    /// The app's configuration, as the plugin stores it: `ClientOverKeychain`'s, so the client's `.default` uses the
    /// same record.
    private let authConfiguration = AuthConfiguration(client: ClientOverKeychain.configuration)
    private var sessionAccount: String {
        AWSCognitoAuthCredentialStore.sessionAccount(for: authConfiguration)
    }

    private var keychain: InMemoryKeychain!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuite: String!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        userDefaultsSuite = "AccessGroupSignedOutRecordTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuite)
    }

    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        keychain = nil
        userDefaults = nil
        try await super.tearDown()
    }

    // MARK: The store

    /// Test that the store saves the signed-out record under an access group, and deletes the record without one
    ///
    /// - Given: a login saved by the plugin's store with an access group, and one saved without
    /// - When:
    ///    - each store ends its session
    /// - Then:
    ///    - the shared service holds `{"noCredentials":{}}`, byte for byte what the client's `.default` writes, and
    ///      the store reads it as no credentials
    ///    - the unshared service holds no session record
    ///
    func testTheStoreSavesTheSignedOutRecordOnlyUnderAnAccessGroup() throws {
        let shared = makeStore(accessGroup: accessGroup)
        try shared.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let unshared = makeStore(accessGroup: nil)
        try unshared.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())

        try shared.deleteCredential()
        try unshared.deleteCredential()

        XCTAssertEqual(sharedRecord(), signedOutRecord)
        XCTAssertEqual(sharedRecord(), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(sharedRecord(), try JSONEncoder().encode(AmplifyCredentials.noCredentials))
        XCTAssertEqual(try shared.retrieveCredential(), .noCredentials)
        XCTAssertNil(keychain.value(service: service, account: sessionAccount))
    }

    /// Test that under an access group the store saves the signed-out record only over a login or a signed-out record
    ///
    /// - Given: the shared service holding, in turn, a user-pool login, a federated identity, the signed-out record, a
    ///   guest's identity, a record the store cannot decode, and nothing
    /// - When:
    ///    - the store with the access group ends its session
    /// - Then:
    ///    - over a login, a federated identity or the signed-out record, the shared service holds
    ///      `{"noCredentials":{}}`
    ///    - over a guest's identity or an unreadable record, the record is deleted, as before
    ///    - with nothing saved, nothing is written
    ///
    func testTheStoreSavesTheSignedOutRecordOnlyOverALoginOrASignedOutRecord() throws {
        let federated = AmplifyCredentials.identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: "federated-identity",
            credentials: LongLivedCredentials.awsCredentials()
        )
        let saved: [(label: String, record: Data?, signsOut: Bool)] = try [
            ("a login", JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool()), true),
            ("a federated identity", JSONEncoder().encode(federated), true),
            ("the signed-out record", signedOutRecord, true),
            ("a guest", JSONEncoder().encode(Self.guest), false),
            ("an unreadable record", Data("not a session".utf8), false),
            ("nothing", nil, false)
        ]
        for (label, record, signsOut) in saved {
            let shared = keychain.store(service: sharedService, accessGroup: accessGroup)
            try shared.remove(sessionAccount)
            if let record {
                try shared.set(record, key: sessionAccount)
            }

            try makeStore(accessGroup: accessGroup).deleteCredential()

            XCTAssertEqual(sharedRecord(), signsOut ? signedOutRecord : nil, label)
        }
    }

    // MARK: Each path that ends the session

    /// Test that a plugin sign-out under an access group saves the signed-out record, and the next launch is signed out
    ///
    /// - Given: alice's login in the shared service, and the plugin configured with the access group
    /// - When:
    ///    - the plugin signs out, locally, then (after alice signs in again) globally
    /// - Then:
    ///    - each sign-out completes, and the shared service holds `{"noCredentials":{}}`
    ///    - a plugin configured over it, as at the next launch, is signed out
    ///    - an app extension's first migration then stops at the record, and its own stale login stays in its
    ///      unshared service
    ///
    func testASignOutSavesTheSignedOutRecord() async throws {
        for globalSignOut in [false, true] {
            try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            let plugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())

            let result = await plugin.signOut(options: .init(globalSignOut: globalSignOut))

            guard let signOut = result as? AWSCognitoSignOutResult, case .complete = signOut else {
                return XCTFail("the sign-out (global: \(globalSignOut)) did not complete: \(result)")
            }
            XCTAssertEqual(sharedRecord(), signedOutRecord, "global: \(globalSignOut)")
            await assertTheNextLaunchIsSignedOut()
            try assertAnExtensionsFirstMigrationStops()
        }
    }

    /// Test that clearing the federation to the identity pool under an access group saves the signed-out record
    ///
    /// - Given: a federated identity in the shared service, and the plugin configured with the access group
    /// - When:
    ///    - the plugin clears the federation
    /// - Then:
    ///    - the shared service holds `{"noCredentials":{}}`, the next launch is signed out, and an app extension's
    ///      first migration stops at the record
    ///
    func testClearingTheFederationSavesTheSignedOutRecord() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(.identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: "federated-identity",
            credentials: LongLivedCredentials.awsCredentials()
        ))
        let plugin = makePlugin(accessGroup: accessGroup, userPool: MockIdentityProvider())

        try await plugin.clearFederationToIdentityPool()

        XCTAssertEqual(sharedRecord(), signedOutRecord)
        await assertTheNextLaunchIsSignedOut()
        try assertAnExtensionsFirstMigrationStops()
    }

    /// Test that a deleted user's local sign-out under an access group saves the signed-out record
    ///
    /// - Given: alice's login in the shared service, and the plugin configured with the access group
    /// - When:
    ///    - the plugin deletes the user
    /// - Then:
    ///    - the shared service holds `{"noCredentials":{}}`, the next launch is signed out, and an app extension's
    ///      first migration stops at the record
    ///
    func testDeletingTheUserSavesTheSignedOutRecord() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let plugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())

        try await plugin.deleteUser()

        XCTAssertEqual(sharedRecord(), signedOutRecord)
        await assertTheNextLaunchIsSignedOut()
        try assertAnExtensionsFirstMigrationStops()
    }

    /// Test that without an access group each path that ends the session still deletes the record
    ///
    /// - Given: alice's login in the unshared service, and the plugin configured without an access group
    /// - When:
    ///    - the plugin signs out; then, signed in again, deletes the user; then, federated, clears the federation
    /// - Then:
    ///    - after each, the unshared service holds no session record, and nothing is saved in the shared service
    ///
    func testWithoutAnAccessGroupEachPathStillDeletesTheRecord() async throws {
        try makeStore(accessGroup: nil).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        _ = await makePlugin(accessGroup: nil, userPool: signOutUserPool()).signOut()
        XCTAssertNil(keychain.value(service: service, account: sessionAccount), "after the sign-out")

        try makeStore(accessGroup: nil).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        try await makePlugin(accessGroup: nil, userPool: signOutUserPool()).deleteUser()
        XCTAssertNil(keychain.value(service: service, account: sessionAccount), "after the deletion")

        try makeStore(accessGroup: nil).saveCredential(.identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: "federated-identity",
            credentials: LongLivedCredentials.awsCredentials()
        ))
        try await makePlugin(accessGroup: nil, userPool: MockIdentityProvider()).clearFederationToIdentityPool()
        XCTAssertNil(keychain.value(service: service, account: sessionAccount), "after clearing the federation")

        XCTAssertNil(sharedRecord())
    }

    /// Test that a sign-out with nothing saved writes nothing under an access group, so the app's first migration
    /// still moves its login
    ///
    /// - Given: nothing saved in the shared service, and an app extension's plugin configured with the access group,
    ///   signed out
    /// - When:
    ///    - the extension signs out, before the app's first launch with the access group
    ///    - then the app's store is configured with the access group and `migrateKeychainItems: true`, with alice's
    ///      login in its unshared service
    /// - Then:
    ///    - the sign-out completes and the shared service holds no session record
    ///    - the app's migration moves alice's login into the shared service
    ///
    func testASignOutWithNothingSavedWritesNothingAndTheAppsLoginStillMigrates() async throws {
        let plugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())

        let result = await plugin.signOut()

        guard let signOut = result as? AWSCognitoSignOutResult, case .complete = signOut else {
            return XCTFail("the sign-out did not complete: \(result)")
        }
        XCTAssertNil(sharedRecord())
        try assertTheAppsFirstMigrationMovesItsLogin()
    }

    /// Test that a guest's sign-out deletes the guest's record under an access group, so the app's first migration
    /// still moves its login
    ///
    /// - Given: a guest's identity in the shared service, and an app extension's plugin configured with the access
    ///   group
    /// - When:
    ///    - the extension signs the guest out, before the app's first launch with the access group
    ///    - then the app's store is configured with the access group and `migrateKeychainItems: true`, with alice's
    ///      login in its unshared service
    /// - Then:
    ///    - the sign-out completes and the shared service holds no session record
    ///    - the app's migration moves alice's login into the shared service
    ///
    func testAGuestsSignOutDeletesTheGuestRecordAndTheAppsLoginStillMigrates() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(Self.guest)
        let plugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())

        let result = await plugin.signOut()

        guard let signOut = result as? AWSCognitoSignOutResult, case .complete = signOut else {
            return XCTFail("the guest's sign-out did not complete: \(result)")
        }
        XCTAssertNil(sharedRecord())
        try assertTheAppsFirstMigrationMovesItsLogin()
    }

    // MARK: After the sign-out

    /// Test that a sign-in after a sign-out replaces the signed-out record
    ///
    /// - Given: the plugin, configured with the access group, signed out, so the shared service holds the signed-out
    ///   record
    /// - When:
    ///    - the plugin signs in with SRP
    /// - Then:
    ///    - the sign-in completes, and the shared service holds the new login
    ///
    func testASignInAfterTheSignOutReplacesTheRecord() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        let signOutPlugin = makePlugin(accessGroup: accessGroup, userPool: signOutUserPool())
        _ = await signOutPlugin.signOut()
        XCTAssertEqual(sharedRecord(), signedOutRecord)

        let plugin = makePlugin(accessGroup: accessGroup, userPool: KeychainQueryParityTests.signInUserPool())
        let result = try await plugin.signIn(username: "alice", password: "password", options: .init())

        XCTAssertTrue(result.isSignedIn)
        let saved = try XCTUnwrap(sharedRecord())
        guard case .userPoolAndIdentityPool = try JSONDecoder().decode(AmplifyCredentials.self, from: saved) else {
            return XCTFail("the shared service does not hold the new login")
        }
    }

    /// Test that the Cognito client's `.default` reads the plugin's signed-out record as signed out
    ///
    /// - Given: the plugin, configured with the access group, signed out, so the shared service holds the signed-out
    ///   record
    /// - When:
    ///    - the client's `.default` in the access group reads its state, and the saved sessions are listed
    /// - Then:
    ///    - `.default` is `.signedOut`, its token provider throws `notSignedIn`, and the record is unchanged
    ///    - the default listing shows no `.default` row; with signed-out rows, `.default` is a signed-out row with no
    ///      label or username, as after the client's own sign-out without a sidecar
    ///
    func testTheClientsDefaultSessionReadsThePluginsSignedOutRecordAsSignedOut() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        _ = await makePlugin(accessGroup: accessGroup, userPool: signOutUserPool()).signOut()
        XCTAssertEqual(sharedRecord(), signedOutRecord)

        let app = ClientOverKeychain(keychain: keychain)
        var client: AmplifyCognitoClient? = try app.client(accessGroup: accessGroup)
        let state = try await XCTUnwrap(client).currentSessionState()
        XCTAssertEqual(state, .signedOut)
        do {
            _ = try await XCTUnwrap(client).userPoolTokenProvider.accessToken()
            XCTFail("a signed-out `.default` returned an access token")
        } catch {
            guard case .notSignedIn? = error as? CredentialsError else {
                return XCTFail("the token provider threw \(error), not notSignedIn")
            }
        }
        client = nil
        await app.waitForBaseline()

        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientOverKeychain.configuration,
            accessGroup: accessGroup,
            includingSignedOut: false,
            dependencies: app.dependencies
        )
        XCTAssertFalse(listed.contains { $0.sessionId == .default })
        let withSignedOut = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientOverKeychain.configuration,
            accessGroup: accessGroup,
            includingSignedOut: true,
            dependencies: app.dependencies
        )
        let row = try XCTUnwrap(withSignedOut.first { $0.sessionId == .default })
        XCTAssertEqual(row.kind, .signedOut)
        XCTAssertNil(row.label)
        XCTAssertNil(row.username)
        XCTAssertEqual(sharedRecord(), signedOutRecord)
    }

    /// Test that an app extension's first access-group transition without migration counts the plugin's signed-out
    /// record, as it counts a login, and keeps its own old service's items
    ///
    /// - Given: the plugin, configured with the access group, signed out, so the shared service holds the signed-out
    ///   record; and an app extension whose unshared service holds bob's stale login and whose `UserDefaults` hold
    ///   no access group
    /// - When:
    ///    - the extension's store is configured with the access group and `migrateKeychainItems: false`
    /// - Then:
    ///    - the shared service is not empty, so the extension's unshared service is not cleared: bob's login stays
    ///      there, and the new store reads no login
    ///
    func testAnExtensionsFirstTransitionWithoutMigrationKeepsItsOwnItems() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        _ = await makePlugin(accessGroup: accessGroup, userPool: signOutUserPool()).signOut()
        XCTAssertEqual(sharedRecord(), signedOutRecord)
        let extensionKeychain = InMemoryKeychain()
        let bob = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool(username: "bob"))
        try extensionKeychain.store(service: service).set(bob, key: sessionAccount)
        let suite = "AccessGroupSignedOutRecordTests.extension.\(UUID().uuidString)"
        let extensionDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { extensionDefaults.removePersistentDomain(forName: suite) }
        let keychain = keychain!

        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: false,
            userDefaults: extensionDefaults,
            makeKeychainStore: { service, accessGroup in
                accessGroup == nil ? extensionKeychain.store(service: service) : keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )

        XCTAssertEqual(try store.retrieveCredential(), .noCredentials)
        XCTAssertEqual(extensionKeychain.value(service: service, account: sessionAccount), bob)
        XCTAssertEqual(sharedRecord(), signedOutRecord)
    }

    // MARK: With the AWSMobileClient logins

    /// Test that the next launch's AWSMobileClient migration drops a login left after a plugin sign-out under an access
    /// group, and still migrates it without one
    ///
    /// - Given: alice's login, and the plugin signed out, with the access group and without; then AWSMobileClient
    ///   stores that still hold a login, as when the sign-out's clear of them failed, or a login was saved there since
    /// - When:
    ///    - the plugin configures over them, as at the next launch, which runs the AWSMobileClient migration
    /// - Then:
    ///    - with the access group, the signed-out record stops the migration: the launch is signed out, the record is
    ///      unchanged, and the AWSMobileClient stores are cleared
    ///    - without one, the sign-out deleted the record, so the old login is migrated into the unshared service, as
    ///      before
    ///
    func testTheNextLaunchDropsAnAWSMobileClientLoginLeftAfterTheSignOutOnlyUnderAnAccessGroup() async throws {
        for accessGroup in [accessGroup, nil] {
            let label = accessGroup == nil ? "without an access group" : "with the access group"
            try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            _ = await makePlugin(accessGroup: accessGroup, userPool: signOutUserPool()).signOut()
            let cleared = TestCounter()
            let legacy = MockKeychainStoreBehavior(data: "legacy", removeAllHandler: { cleared.increment() })

            let plugin = makePlugin(
                accessGroup: accessGroup,
                userPool: MockIdentityProvider(),
                legacyStore: { _ in legacy }
            )
            _ = try? await plugin.getCurrentUser()

            let saved = keychain.value(
                service: accessGroup == nil ? service : sharedService,
                accessGroup: accessGroup,
                account: sessionAccount
            )
            if accessGroup == nil {
                let migrated = try JSONDecoder().decode(AmplifyCredentials.self, from: XCTUnwrap(saved, label))
                guard case .userPoolAndIdentityPool = migrated else {
                    return XCTFail("\(label): the old login was not migrated")
                }
            } else {
                XCTAssertEqual(saved, signedOutRecord, label)
                guard case .configured(.signedOut, _, _) = await plugin.authStateMachine.currentState else {
                    return XCTFail("\(label): the next launch is in \(await plugin.authStateMachine.currentState)")
                }
            }
            XCTAssertGreaterThan(cleared.get(), 0, label)
        }
    }

    /// Test that a guest the Cognito client's `.default` fetches after a plugin sign-out under an access group clears
    /// the AWSMobileClient logins first
    ///
    /// - Given: the plugin, configured with the access group, signed out, so the shared service holds the signed-out
    ///   record; and AWSMobileClient logins in the app's keychain, as when the sign-out's clear of them failed
    /// - When:
    ///    - the client's `.default` in the access group fetches its session, which fetches a guest
    /// - Then:
    ///    - the shared service holds the guest, and the AWSMobileClient logins are gone, so a plugin build has none
    ///      to migrate over the guest
    ///
    func testAGuestTheClientFetchesAfterThePluginsSignOutClearsTheAWSMobileClientLogins() async throws {
        try makeStore(accessGroup: accessGroup).saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        _ = await makePlugin(accessGroup: accessGroup, userPool: signOutUserPool()).signOut()
        XCTAssertEqual(sharedRecord(), signedOutRecord)
        let legacyServices = SessionRecordStore.legacyLoginServices(for: PoolNamespace(authConfiguration))
        XCTAssertFalse(legacyServices.isEmpty)
        for legacyService in legacyServices {
            try keychain.store(service: legacyService).set(Data("legacy".utf8), key: "tokens.alice")
        }

        let app = ClientOverKeychain(keychain: keychain, clearsLegacyLogins: true)
        var client: AmplifyCognitoClient? = try app.client(accessGroup: accessGroup)
        _ = try await XCTUnwrap(client).fetchAuthSession()
        client = nil
        await app.waitForBaseline()

        let saved = try JSONDecoder().decode(AmplifyCredentials.self, from: XCTUnwrap(sharedRecord()))
        guard case .identityPoolOnly = saved else {
            return XCTFail("the shared service does not hold a guest")
        }
        for legacyService in legacyServices {
            XCTAssertNil(keychain.value(service: legacyService, account: "tokens.alice"), legacyService)
        }
    }

    // MARK: A rollback after a configuration carry

    /// Test that a plugin sign-out after a configuration carry, under an access group, survives a rollback to the
    /// build with the earlier configuration, and without one leaves that build the earlier copy
    ///
    /// - Given: alice saved under a user-pool-only configuration; the plugin's store under the configuration that adds
    ///   the identity pool, which carries her to its key and keeps the earlier copy; then that store ends the session
    /// - When:
    ///    - the store is built with the earlier configuration, as by a rollback to that build, which runs the
    ///      plugin's rule back to it
    /// - Then:
    ///    - with the access group, the rule carries the signed-out record over the earlier copy: that build reads
    ///      `.noCredentials`, as after a sign-out through the client
    ///    - without one, the sign-out deleted the record, so there is nothing to carry and that build reads alice
    ///
    func testASignOutAfterACarrySurvivesARollbackOnlyUnderAnAccessGroup() throws {
        let earlier = AuthConfiguration(client: ClientOverKeychain.userPoolOnlyConfiguration)
        for accessGroup in [accessGroup, nil] {
            let label = accessGroup == nil ? "without an access group" : "with the access group"
            let earlierStore = makeStore(accessGroup: accessGroup, configuration: earlier)
            try earlierStore.saveCredential(.userPoolOnly(signedInData: SignedInData(
                signedInDate: Date(),
                signInMethod: .apiBased(.userSRP),
                cognitoUserPoolTokens: LongLivedCredentials.tokens(username: "alice")
            )))
            let alice = try earlierStore.retrieveCredential()
            let current = makeStore(accessGroup: accessGroup)
            XCTAssertEqual(try current.retrieveCredential(), alice, label)

            try current.deleteCredential()

            let rolledBack = makeStore(accessGroup: accessGroup, configuration: earlier)
            XCTAssertEqual(try rolledBack.retrieveCredential(), accessGroup == nil ? alice : .noCredentials, label)
        }
    }

    // MARK: Helpers

    private func sharedRecord() -> Data? {
        keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount)
    }

    /// A plugin configured over the shared record, as at the next launch, is signed out, and the record is unchanged.
    private func assertTheNextLaunchIsSignedOut(file: StaticString = #filePath, line: UInt = #line) async {
        let plugin = makePlugin(accessGroup: accessGroup, userPool: MockIdentityProvider())
        do {
            let user = try await plugin.getCurrentUser()
            XCTFail("the next launch is signed in as \(user.username)", file: file, line: line)
        } catch {
            guard case AuthError.signedOut = error else {
                return XCTFail("the next launch failed with \(error), not signedOut", file: file, line: line)
            }
        }
        guard case .configured(.signedOut, _, _) = await plugin.authStateMachine.currentState else {
            return XCTFail("the next launch is in \(await plugin.authStateMachine.currentState)", file: file, line: line)
        }
        XCTAssertEqual(sharedRecord(), signedOutRecord, file: file, line: line)
    }

    /// An app extension's first configuration with the access group and `migrateKeychainItems: true`, its unshared
    /// service holding bob's stale login and its `UserDefaults` no access group, stops at the signed-out record: the
    /// record stays, the new store reads no login, and bob's login stays in the extension's own service.
    private func assertAnExtensionsFirstMigrationStops(file: StaticString = #filePath, line: UInt = #line) throws {
        // Only a sign-in writes a device record; none was saved, so the signed-out record alone stops the migration.
        let pluginAccounts = try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts()
            .filter { !SessionRecordAccount.isClientSessionRecord($0) }
        XCTAssertEqual(pluginAccounts.sorted(), ["authConfiguration", sessionAccount].sorted(), file: file, line: line)
        let extensionKeychain = InMemoryKeychain()
        let bob = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool(username: "bob"))
        try extensionKeychain.store(service: service).set(bob, key: sessionAccount)
        let suite = "AccessGroupSignedOutRecordTests.extension.\(UUID().uuidString)"
        let extensionDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { extensionDefaults.removePersistentDomain(forName: suite) }
        let keychain = keychain!

        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: true,
            userDefaults: extensionDefaults,
            makeKeychainStore: { service, accessGroup in
                accessGroup == nil ? extensionKeychain.store(service: service) : keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )

        XCTAssertEqual(sharedRecord(), signedOutRecord, file: file, line: line)
        XCTAssertEqual(try store.retrieveCredential(), .noCredentials, file: file, line: line)
        XCTAssertEqual(extensionKeychain.value(service: service, account: sessionAccount), bob, file: file, line: line)
    }

    /// A guest's identity: an identity pool identity with no user pool tokens and no federated identity.
    private static let guest = AmplifyCredentials.identityPoolOnly(
        identityID: "guest-identity-id",
        credentials: LongLivedCredentials.awsCredentials()
    )

    /// The app's first configuration with the access group and `migrateKeychainItems: true`, its unshared service
    /// holding alice's login and its `UserDefaults` no access group, moves alice's login into the shared service. The
    /// app's unshared service is in the same keychain as the shared service, so the migration can move items between
    /// them.
    private func assertTheAppsFirstMigrationMovesItsLogin(file: StaticString = #filePath, line: UInt = #line) throws {
        let keychain = keychain!
        let alice = try JSONEncoder().encode(LongLivedCredentials.userPoolAndIdentityPool(username: "alice"))
        try keychain.store(service: service).set(alice, key: sessionAccount)
        let suite = "AccessGroupSignedOutRecordTests.app.\(UUID().uuidString)"
        let appDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { appDefaults.removePersistentDomain(forName: suite) }

        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: true,
            userDefaults: appDefaults,
            makeKeychainStore: { service, accessGroup in
                keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )

        XCTAssertEqual(sharedRecord(), alice, "alice's login was not migrated", file: file, line: line)
        XCTAssertEqual(
            try store.retrieveCredential(),
            try JSONDecoder().decode(AmplifyCredentials.self, from: alice),
            file: file,
            line: line
        )
        XCTAssertNil(keychain.value(service: service, account: sessionAccount), file: file, line: line)
    }

    /// The plugin's credential store over the shared keychain, as `makeCredentialStore` builds it, without migration:
    /// the app's configuration's, unless `configuration` is given.
    private func makeStore(accessGroup: String?, configuration: AuthConfiguration? = nil) -> AWSCognitoAuthCredentialStore {
        let keychain = keychain!
        return AWSCognitoAuthCredentialStore(
            authConfiguration: configuration ?? authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: false,
            userDefaults: userDefaults,
            makeKeychainStore: { service, accessGroup in
                keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )
    }

    private func signOutUserPool() -> MockIdentityProvider {
        MockIdentityProvider(
            mockRevokeTokenResponse: { _ in .testData },
            mockGlobalSignOutResponse: { _ in .testData },
            mockDeleteUserOutput: { _ in DeleteUserOutput() }
        )
    }

    /// A plugin as `configure(using:)` builds it, with its credential store from `makeStore(accessGroup:)` and only
    /// the Cognito service calls mocked. Its credential store machine starts idle, so its first load skips the
    /// AWSMobileClient migration, unless `legacyStore` is given: it then starts as at a launch, and the migration
    /// runs over those stores first.
    private func makePlugin(
        accessGroup: String?,
        userPool: CognitoUserPoolBehavior,
        legacyStore: (@Sendable (String) -> any KeychainItemStoreBehavior)? = nil
    ) -> AWSCognitoAuthPlugin {
        let identity = MockIdentity(
            mockGetIdResponse: { _ in .init(identityId: "client-identity-id") },
            mockGetCredentialsResponse: { input in
                .init(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: "refreshedAccessKey",
                        expiration: Date(timeIntervalSinceNow: 3_600),
                        secretKey: "refreshedSecret",
                        sessionToken: "refreshedSession"
                    ),
                    identityId: input.identityId
                )
            }
        )
        let factory = AuthEnvironmentFactory(
            authConfiguration: authConfiguration,
            makeUserPool: { userPool },
            makeIdentityClient: { identity },
            credentialStoreFactory: { [self] in makeStore(accessGroup: accessGroup) },
            legacyKeychainStoreFactory: legacyStore ?? Defaults.makeLegacyStore(service:),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest")),
            userPoolAnalytics: { MockAnalyticsHandler() },
            makeURLSession: { URLSession(configuration: .ephemeral) },
            makeAdvancedSecurity: Defaults.makeDefaultASF
        )
        let credentialStoreMachine = CredentialStoreStateMachine(
            resolver: CredentialStoreState.Resolver(),
            environment: factory.makeCredentialEnvironment(),
            initialState: legacyStore == nil ? .idle : .notConfigured
        )
        let authEnvironment = factory.makeAuthEnvironment(
            credentialsClient: CredentialStoreOperationClient(credentialStoreStateMachine: credentialStoreMachine)
        )
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: AuthStateMachine(resolver: AuthState.Resolver(logger: AmplifyEngineLogRouter()), environment: authEnvironment),
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        settleConfigureOperationOnTeardown(of: plugin)
        return plugin
    }
}
