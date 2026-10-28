//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(AmplifyExperimental) import AmplifyFoundation
import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The plugin's signed-out record under an access group against the other migrations: an app extension's first
/// transition without migration, the AWSMobileClient migration at the next launch, a guest the Cognito client fetches
/// over the record, and a rollback after a configuration carry. Beside `AccessGroupSignedOutRecordTests.swift`, whose
/// helpers these use.
extension AccessGroupSignedOutRecordTests {

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
}
