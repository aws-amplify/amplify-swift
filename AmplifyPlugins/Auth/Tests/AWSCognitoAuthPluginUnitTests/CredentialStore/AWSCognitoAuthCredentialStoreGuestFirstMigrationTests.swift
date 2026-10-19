//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The access-group migration when another process in the group fetched a session before the app's first launch
/// after the update: an app extension's plugin, or the Cognito client's default session, finds the shared service
/// empty, gets a guest identity and saves it there. That guest's record does not stop the migration of the app's
/// login, fresh or resumed. A login in the shared service still does, and a guest is never replaced by anything but
/// a login.
///
/// The app runs the plugin's real credential store, through its test seam, over an in-memory keychain shared with the
/// extension. The extension's own unshared service and `UserDefaults` are its own.
class AWSCognitoAuthCredentialStoreGuestFirstMigrationTests: XCTestCase {

    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroup = "group.acme"
    private let accessGroupKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"
    private let migrationInProgressKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroupMigrationInProgress"

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
        userDefaultsSuite = "AWSCognitoAuthCredentialStoreGuestFirstMigrationTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuite)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        keychain = nil
        userDefaults = nil
        super.tearDown()
    }

    // MARK: Fresh migration

    /// An app extension whose Cognito client's `.default` fetches a session first no longer strands the app's login.
    ///
    /// - Given: the app's plugin, without an access group, signed in as alice; and an app extension that runs the
    ///   client's `.default` with the access group and fetches a session before the app's first launch after the
    ///   update: it gets guest credentials and saves a guest's record in the shared service
    /// - When:
    ///    - the app's plugin is configured with the access group and migration
    /// - Then:
    ///    - alice's login moves into the shared service, replacing the guest, and the new store reads it
    ///    - nothing of the plugin's is left in the unshared service, and the access group is recorded
    func testAnExtensionsDefaultSessionFetchingFirstDoesNotStrandTheAppsLogin() async throws {
        let alice = try signInTheAppWithoutAnAccessGroup()
        let widget = ClientOverKeychain(keychain: keychain)
        widget.script(userPool: ClientOverKeychain.userPool())
        var client: AmplifyCognitoClient? = try widget.client(accessGroup: accessGroup)
        let fetched = try await XCTUnwrap(client).fetchAuthSession()
        client = nil
        await widget.waitForBaseline()
        XCTAssertNoThrow(try fetched.awsCredentialsResult.get())
        XCTAssertThrowsError(try fetched.userPoolTokensResult.get())
        try assertSharedSessionIsAGuests()

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), alice)
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertEqual(userDefaults.string(forKey: accessGroupKey), accessGroup)
    }

    /// An app extension whose plugin fetches a session first no longer strands the app's login.
    ///
    /// - Given: the app's plugin, without an access group, signed in as alice; and an app extension whose plugin,
    ///   configured with the access group and migration, finds nothing to migrate and then fetches a session: it gets
    ///   guest credentials and saves a guest's record in the shared service
    /// - When:
    ///    - the app's plugin is configured with the access group and migration
    /// - Then:
    ///    - alice's login moves into the shared service, replacing the guest, and the new store reads it
    ///    - nothing of the plugin's is left in the unshared service
    func testAnExtensionsPluginFetchingASessionFirstDoesNotStrandTheAppsLogin() async throws {
        let alice = try signInTheAppWithoutAnAccessGroup()
        _ = makeExtensionStore(migrate: true)
        let extensionPlugin = makePluginOverKeychain(
            keychain.store(service: sharedService, accessGroup: accessGroup),
            authConfiguration: authConfiguration,
            userPool: MockIdentityProvider()
        )
        let fetched = try await extensionPlugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertFalse(fetched.isSignedIn)
        try assertSharedSessionIsAGuests()

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), alice)
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
    }

    /// A login in the shared service still stops the migration: the app's login never replaces it.
    ///
    /// - Given: the app's plugin, without an access group, signed in as alice; and, in turn, a shared service holding
    ///   bob's login with user pool tokens, and one holding a federated identity, each saved by an app extension
    /// - When:
    ///    - the app's plugin is configured with the access group and migration
    /// - Then:
    ///    - the migration is skipped: alice's items stay in the unshared service, and the shared login is unchanged
    func testALoginInTheSharedServiceStillStopsTheMigration() throws {
        let federated = AmplifyCredentials.identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: "federated-identity",
            credentials: LongLivedCredentials.awsCredentials()
        )
        for (name, login) in [("bob", LongLivedCredentials.userPoolAndIdentityPool(username: "bob")), ("federated", federated)] {
            keychain = InMemoryKeychain()
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            _ = try signInTheAppWithoutAnAccessGroup()
            let appsAccounts = try keychain.store(service: service).allAccounts()
            let saved = try JSONEncoder().encode(login)
            try keychain.store(service: sharedService, accessGroup: accessGroup).set(saved, key: sessionAccount)

            _ = makeStore(accessGroup: accessGroup, migrate: true)

            XCTAssertEqual(try keychain.store(service: service).allAccounts(), appsAccounts, name)
            XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount), saved, name)
        }
    }

    /// A guest in the shared service is not replaced by the app's guest: only a login replaces one.
    ///
    /// - Given: the app's plugin, without an access group, holding a guest identity; and an app extension that
    ///   fetched first and saved its own guest identity in the shared service
    /// - When:
    ///    - the app's plugin is configured with the access group and migration
    /// - Then:
    ///    - the migration is skipped, as before: the shared service keeps the extension's guest, which the new store
    ///      reads, and the app's guest stays in the unshared service
    func testAGuestInTheSharedServiceIsNotReplacedByTheAppsGuest() throws {
        let appsGuest = AmplifyCredentials.identityPoolOnly(identityID: "apps-guest", credentials: LongLivedCredentials.awsCredentials())
        let extensionsGuest = AmplifyCredentials.identityPoolOnly(identityID: "extensions-guest", credentials: LongLivedCredentials.awsCredentials())
        try makeStore(accessGroup: nil).saveCredential(appsGuest)
        let appsAccounts = try keychain.store(service: service).allAccounts()
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(JSONEncoder().encode(extensionsGuest), key: sessionAccount)

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), extensionsGuest)
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), appsAccounts)
        XCTAssertEqual(try makeStore(accessGroup: nil).retrieveCredential(), appsGuest)
    }

    /// A guest the app migrated is kept by an app extension's first launch with nothing to migrate.
    ///
    /// - Given: the app, with the access group, holding a guest identity in the shared service; and an app extension
    ///   with its own empty unshared service and its own `UserDefaults`, which hold no access group
    /// - When:
    ///    - the extension's plugin is configured with the access group and migration for the first time
    /// - Then:
    ///    - the migration is skipped: the shared service still holds the app's guest
    func testAnExtensionWithNothingToMigrateKeepsTheAppsMigratedGuest() throws {
        let appsGuest = AmplifyCredentials.identityPoolOnly(identityID: "apps-guest", credentials: LongLivedCredentials.awsCredentials())
        try makeStore(accessGroup: accessGroup).saveCredential(appsGuest)

        _ = makeExtensionStore(migrate: true)

        XCTAssertEqual(try makeStore(accessGroup: accessGroup).retrieveCredential(), appsGuest)
    }

    // MARK: Resumed migration

    /// A migration interrupted before its first move resumes over a guest an app extension's `.default` saved since.
    ///
    /// - Given: the state a migration killed just before its first move leaves: alice's items all still in the
    ///   unshared service, the mark naming the access group, and no access group recorded; then an app extension's
    ///   client `.default`, with the access group, fetches a session and saves a guest's record in the shared service
    /// - When:
    ///    - the app launches again with the access group and migration
    /// - Then:
    ///    - alice's login replaces the guest, and the new store reads it
    ///    - nothing of the plugin's is left in the unshared service but the configuration record, which collides
    ///      with the extension's and stays, as any colliding item does
    ///    - the access group is recorded and the mark is gone
    func testAnInterruptedMigrationResumesOverAGuestAnExtensionSavedSince() async throws {
        let alice = try signInTheAppWithoutAnAccessGroup()
        userDefaults.set(accessGroup, forKey: migrationInProgressKey)
        let widget = ClientOverKeychain(keychain: keychain)
        widget.script(userPool: ClientOverKeychain.userPool())
        var client: AmplifyCognitoClient? = try widget.client(accessGroup: accessGroup)
        _ = try await XCTUnwrap(client).fetchAuthSession()
        client = nil
        await widget.waitForBaseline()
        try assertSharedSessionIsAGuests()

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), alice)
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), ["authConfiguration"])
        XCTAssertEqual(userDefaults.string(forKey: accessGroupKey), accessGroup)
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
    }

    /// A resumed migration still keeps a login an app extension saved in the shared service since the interruption.
    ///
    /// - Given: the state a migration killed just before its first move leaves, with alice's items in the unshared
    ///   service; then an app extension signs bob in and saves his login in the shared service
    /// - When:
    ///    - the app launches again with the access group and migration
    /// - Then:
    ///    - bob's login is unchanged and the new store reads it; alice's session collides with it and stays in the
    ///      unshared service
    func testAResumedMigrationKeepsALoginAnExtensionSavedSince() throws {
        _ = try signInTheAppWithoutAnAccessGroup()
        userDefaults.set(accessGroup, forKey: migrationInProgressKey)
        let bob = LongLivedCredentials.userPoolAndIdentityPool(username: "bob")
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(JSONEncoder().encode(bob), key: sessionAccount)

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), bob)
        XCTAssertTrue(try keychain.store(service: service).allAccounts().contains(sessionAccount))
    }

    /// A resumed migration does not replace a guest an app extension saved since with the app's guest either.
    ///
    /// - Given: the state a migration killed just before its first move leaves, the app holding a guest identity in
    ///   the unshared service; then an app extension saves its own guest identity in the shared service
    /// - When:
    ///    - the app launches again with the access group and migration
    /// - Then:
    ///    - the shared service keeps the extension's guest, and the app's guest stays in the unshared service
    func testAResumedMigrationDoesNotReplaceAGuestWithTheAppsGuest() throws {
        let appsGuest = AmplifyCredentials.identityPoolOnly(identityID: "apps-guest", credentials: LongLivedCredentials.awsCredentials())
        let extensionsGuest = AmplifyCredentials.identityPoolOnly(identityID: "extensions-guest", credentials: LongLivedCredentials.awsCredentials())
        try makeStore(accessGroup: nil).saveCredential(appsGuest)
        userDefaults.set(accessGroup, forKey: migrationInProgressKey)
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(JSONEncoder().encode(extensionsGuest), key: sessionAccount)

        let store = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try store.retrieveCredential(), extensionsGuest)
        XCTAssertEqual(
            try JSONDecoder().decode(AmplifyCredentials.self, from: XCTUnwrap(keychain.value(service: service, account: sessionAccount))),
            appsGuest
        )
    }

    // MARK: Helpers

    /// The app's plugin, without an access group, signed in as alice with device records. Returns her login.
    private func signInTheAppWithoutAnAccessGroup() throws -> AmplifyCredentials {
        let store = makeStore(accessGroup: nil)
        let alice = LongLivedCredentials.userPoolAndIdentityPool()
        try store.saveCredential(alice)
        try store.saveDevice(.metadata(.init(deviceKey: "device", deviceGroupKey: "group", deviceSecret: "secret")), for: "alice")
        try store.saveASFDevice("asf-device", for: "alice")
        return alice
    }

    private func assertSharedSessionIsAGuests(file: StaticString = #filePath, line: UInt = #line) throws {
        let saved = try XCTUnwrap(
            keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount),
            "nothing was saved in the shared service",
            file: file,
            line: line
        )
        guard case .identityPoolOnly = try JSONDecoder().decode(AmplifyCredentials.self, from: saved) else {
            return XCTFail("the shared service's record is not a guest's", file: file, line: line)
        }
    }

    private func makeStore(accessGroup: String?, migrate: Bool = false) -> AWSCognitoAuthCredentialStore {
        let keychain = keychain!
        return AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrate,
            userDefaults: userDefaults,
            makeKeychainStore: { service, accessGroup in
                keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )
    }

    /// An app extension's credential store with the access group: its unshared service and `UserDefaults` are its
    /// own, empty; the access group's shared service is the app's.
    private func makeExtensionStore(migrate: Bool) -> AWSCognitoAuthCredentialStore {
        let keychain = keychain!
        let extensionKeychain = InMemoryKeychain()
        let suite = "AWSCognitoAuthCredentialStoreGuestFirstMigrationTests.extension.\(UUID().uuidString)"
        let extensionDefaults = UserDefaults(suiteName: suite)!
        defer { extensionDefaults.removePersistentDomain(forName: suite) }
        return AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrate,
            userDefaults: extensionDefaults,
            makeKeychainStore: { service, accessGroup in
                accessGroup == nil ? extensionKeychain.store(service: service) : keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )
    }
}
