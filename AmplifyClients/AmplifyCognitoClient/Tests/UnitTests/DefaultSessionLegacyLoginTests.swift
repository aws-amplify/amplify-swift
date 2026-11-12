//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default` is the Auth plugin's saved login, and every plugin configure first migrates the AWSMobileClient logins into
/// it when it holds no session, or only a guest. So `.default`'s sign-out and purge clear those logins, as the plugin's
/// own sign-out does (`ClearCredentialStore`); named sessions never touch them.
final class DefaultSessionLegacyLoginTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let pools = StorageFixtures.pools
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: The services

    /// - Given: each pool configuration
    /// - When: the AWSMobileClient services are named
    /// - Then:
    ///    - they are the engine's own list for that configuration, the one the plugin's sign-out clears: the user pool
    ///      service with a user pool, the identity pool's with an identity pool, and always the AWSMobileClient one
    func testTheServicesAreThePluginsForEachPoolConfiguration() throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "the test host has a bundle identifier")
        let userPool = "\(bundle).AWSCognitoIdentityUserPool"
        let identityPool = "\(bundle).AWSCognitoCredentialsProvider.\(StorageFixtures.identityPoolId)"
        let mobileClient = "\(String(describing: Bundle.main.bundleIdentifier)).AWSMobileClient"
        let cases: [(AuthClientConfiguration, [String])] = [
            (ClientFixtures.configuration, [userPool, identityPool, mobileClient]),
            (ClientFixtures.userPoolOnlyConfiguration, [userPool, mobileClient]),
            (ClientFixtures.identityPoolOnlyConfiguration, [identityPool, mobileClient])
        ]

        for (configuration, expected) in cases {
            let services = SessionRecordStore.legacyLoginServices(for: configuration.poolNamespace)
            XCTAssertEqual(services, expected)
            XCTAssertEqual(services, MigrateLegacyCredentialStore.legacyServiceKeys(for: AuthConfiguration(client: configuration)))
        }
    }

    /// - Given: a store over the real keychain, and one a test builds
    /// - When: their AWSMobileClient stores are built
    /// - Then:
    ///    - the real one has one item store per service: first the plugin's services for the pools
    ///      (`legacyLoginServices(for:)`), then only other identity pools' `<bundle>.AWSCognitoCredentialsProvider.*`
    ///      services, whichever the real keychain lists; each with no access group, even when the namespace has one
    ///    - a test's has none, so it never reaches them
    func testOnlyTheRealKeychainsStoreReachesTheServices() throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "the test host has a bundle identifier")
        let namespace = SessionStorageNamespace(pools: pools, accessGroup: "group.example")
        let stores = SessionRecordStore(namespace: namespace).legacyLoginStores()
        let own = SessionRecordStore.legacyLoginServices(for: pools)

        let services = stores.compactMap { ($0 as? KeychainItemStore)?.attributes.service }
        XCTAssertEqual(services.count, stores.count, "every store is a keychain item store")
        XCTAssertEqual(Array(services.prefix(own.count)), own)
        let others = services.dropFirst(own.count)
        XCTAssertTrue(
            others.allSatisfy { $0.hasPrefix("\(bundle).\(SessionRecordStore.legacyCredentialsProviderService).") },
            "only other identity pools' credentials services follow the plugin's"
        )
        XCTAssertEqual(Set(others).count, others.count, "no service is listed twice")
        XCTAssertTrue(Set(others).isDisjoint(with: own), "no service of the plugin's is listed twice")
        XCTAssertEqual(stores.compactMap { ($0 as? KeychainItemStore)?.attributes.accessGroup }, [])
        XCTAssertTrue(harness.keychain.recordStore(for: namespace).legacyLoginStores().isEmpty)
    }

    // MARK: The store

    /// - Given: alice's saved login under `.default`, and an AWSMobileClient login in each of the three services
    /// - When: `.default` is signed out
    /// - Then:
    ///    - the saved login holds `{"noCredentials":{}}`, and the three services are empty
    func testASignOutClearsTheAWSMobileClientLogins() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        seedLegacyLogins()

        XCTAssertEqual(try store().signOut(.default), .signedOut)

        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.noCredentials)
        assertLegacyLogins(present: false)
    }

    /// - Given: alice's saved login under `.default`, and an AWSMobileClient login in each of the three services
    /// - When: `.default` is purged
    /// - Then:
    ///    - the saved login is gone, and the three services are empty
    func testAPurgeClearsTheAWSMobileClientLogins() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        seedLegacyLogins()

        try store().purge(.default)

        XCTAssertNil(harness.keychain.value(pluginAccount))
        assertLegacyLogins(present: false)
    }

    /// - Given: alice's saved login under `.default`, and AWSMobileClient logins
    /// - When: a sign-out that revoked other credentials is superseded, and a named session signs out and is purged
    /// - Then:
    ///    - none of them clears the AWSMobileClient logins: `.default` is still signed in after the first, and a named
    ///      session is not the plugin's login
    func testOnlyADefaultSessionThatIsEndingClearsThem() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        try harness.signIn(work, .signedIn("bob"))
        seedLegacyLogins()
        let store = store()

        XCTAssertEqual(try store.signOut(.default, removing: Data("other credentials".utf8)), .superseded)
        XCTAssertEqual(try store.signOut(work), .signedOut)
        try store.purge(work)

        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.userPoolAndIdentityPool)
        assertLegacyLogins(present: true)
    }

    /// The AWSMobileClient logins are cleared before the signed-out write: a sign-out whose write fails must not leave a
    /// login a plugin build would migrate.
    ///
    /// - Given: alice's saved login under `.default`, AWSMobileClient logins, and every write of the saved login failing
    /// - When: `.default` is signed out
    /// - Then:
    ///    - the sign-out throws, and the saved login still holds alice's credentials
    ///    - the AWSMobileClient logins are already cleared
    func testASignOutWhoseWriteFailsHasClearedThem() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        seedLegacyLogins()
        harness.keychain.failingWrites(of: pluginAccount, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store().signOut(.default))

        harness.keychain.clearFailures()
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.userPoolAndIdentityPool)
        assertLegacyLogins(present: false)
    }

    /// An unreadable saved login is replaced with the signed-out record, and the AWSMobileClient logins are cleared
    /// before that replacement too: a replacement that fails leaves bytes a plugin build reads as no session, so a login
    /// left beside them would be migrated.
    ///
    /// - Given: `.default`'s saved login holding bytes that are not the plugin's format, AWSMobileClient logins, and every
    ///   write of the saved login failing
    /// - When: `.default` is signed out
    /// - Then:
    ///    - the sign-out throws, and the saved login still holds the unreadable bytes
    ///    - the AWSMobileClient logins are already cleared
    func testASignOutWhoseReplacementOfAnUnreadableLoginFailsHasClearedThem() throws {
        harness.keychain.put(StorageFixtures.corruptRecord, pluginAccount)
        seedLegacyLogins()
        harness.keychain.failingWrites(of: pluginAccount, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store().signOut(.default))

        harness.keychain.clearFailures()
        XCTAssertEqual(harness.keychain.value(pluginAccount), StorageFixtures.corruptRecord)
        assertLegacyLogins(present: false)
    }

    /// The AWSMobileClient logins are cleared before the purge's delete: once the saved login is gone, a plugin build
    /// migrates any login left.
    ///
    /// - Given: alice's saved login under `.default`, AWSMobileClient logins, and every removal of the saved login failing
    /// - When: `.default` is purged
    /// - Then:
    ///    - the purge throws, and the saved login is kept
    ///    - the AWSMobileClient logins are already cleared
    func testAPurgeWhoseDeleteFailsHasClearedThem() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        seedLegacyLogins()
        harness.keychain.failingRemovals(of: pluginAccount, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store().purge(.default))

        harness.keychain.clearFailures()
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.userPoolAndIdentityPool)
        assertLegacyLogins(present: false)
    }

    /// The AWSMobileClient logins are cleared before the saved login is written or deleted.
    ///
    /// - Given: alice's saved login under `.default`, and AWSMobileClient logins
    /// - When: `.default` is signed out, and in another run purged
    /// - Then:
    ///    - each AWSMobileClient service is cleared while the saved login still holds alice's credentials
    ///    - after the sign-out or purge, the AWSMobileClient logins are gone
    func testTheyAreClearedFirst() throws {
        for purge in [false, true] {
            harness = ClientHarness()
            harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
            seedLegacyLogins()
            let order = ClearOrder()
            let keychain = harness.keychain
            let pluginAccount = pluginAccount
            let services = services
            let store = store(legacyLoginStores: {
                services.map { service in
                    ObservedItemStore(keychain.itemStore(service: service)) {
                        order.record(cleared: keychain.value(pluginAccount))
                    }
                }
            })

            if purge {
                try store.purge(.default)
            } else {
                XCTAssertEqual(try store.signOut(.default), .signedOut)
            }

            let label = purge ? "purge" : "sign-out"
            XCTAssertEqual(order.savedLoginsSeen.count, services.count, label)
            XCTAssertTrue(
                order.savedLoginsSeen.allSatisfy { $0 == PluginRecordFixtures.userPoolAndIdentityPool },
                "\(label): the saved login was written or deleted before the AWSMobileClient logins were cleared"
            )
            assertLegacyLogins(present: false, label)
        }
    }

    /// - Given: alice's saved login under `.default`, and AWSMobileClient stores whose clear fails
    /// - When: `.default` signs out, and is purged
    /// - Then:
    ///    - both succeed, and each logs one warning per store, naming no one
    func testAFailedClearIsBestEffort() throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        let store = store(legacyLoginStores: { [UnclearableItemStore(), UnclearableItemStore()] })
        let sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        defer { AmplifyLogging.removeSink(sink) }

        XCTAssertEqual(try store.signOut(.default), .signedOut)
        try store.purge(.default)

        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(
            sink.lines(in: [ClientLog.category(ClientLog.sessionRecordStore)]),
            Array(repeating: SessionRecordStore.legacyLoginClearFailedWarning, count: 4)
        )
    }

    /// A `.default` sign-out or purge also clears the AWSMobileClient credentials of every other identity pool the app's
    /// keychain holds, which the plugin's services for the configuration don't name.
    ///
    /// - Given: in turn, a configuration with both pools, one with the user pool only and one with the identity pool
    ///   only; `.default` saved; AWSMobileClient logins in the configuration's services, and in two other identity
    ///   pools' credentials services of this app; and two services that are not this app's AWSMobileClient
    ///   credentials (another app's, and an unrelated one of this app)
    /// - When: `.default` is signed out, and in another run purged
    /// - Then:
    ///    - every `<bundle>.AWSCognitoCredentialsProvider.*` service of this app is empty, and so are the
    ///      configuration's own services; the two other services keep their items
    ///    - the user pool service is cleared only with a user pool configured
    func testASignOutOrPurgeClearsEveryIdentityPoolsAWSMobileClientCredentials() throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "the test host has a bundle identifier")
        let otherIdentityPools = [
            "\(bundle).AWSCognitoCredentialsProvider.us-east-1:other-a",
            "\(bundle).AWSCognitoCredentialsProvider.us-east-1:other-b"
        ]
        let notThisApps = ["other.bundle.AWSCognitoCredentialsProvider.us-east-1:other-a", "\(bundle).SomethingElse"]
        let userPoolService = "\(bundle).AWSCognitoIdentityUserPool"
        let configurations = [
            ClientFixtures.configuration,
            ClientFixtures.userPoolOnlyConfiguration,
            ClientFixtures.identityPoolOnlyConfiguration
        ]
        for configuration in configurations {
            for purge in [false, true] {
                harness = ClientHarness()
                let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil)
                let own = SessionRecordStore.legacyLoginServices(for: namespace.pools)
                let listed = own + otherIdentityPools + notThisApps + [userPoolService]
                let keychain = harness.keychain
                for service in Set(listed) {
                    keychain.put(Data("legacy".utf8), "tokens.alice", service: service)
                }
                keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, SessionRecordKey.pluginSessionAccount(in: namespace.pools))
                let store = store(for: namespace, legacyLoginStores: {
                    SessionRecordStore.legacyLoginStores(
                        for: namespace.pools,
                        listServices: { listed.shuffled() },
                        makeStore: { keychain.itemStore(service: $0) }
                    )
                })

                if purge {
                    try store.purge(.default)
                } else {
                    _ = try store.signOut(.default)
                }

                let label = "\(namespace.pools), purge: \(purge)"
                for service in Set(own + otherIdentityPools) {
                    XCTAssertNil(keychain.value(service: service, account: "tokens.alice"), "\(label): \(service)")
                }
                for service in notThisApps {
                    XCTAssertNotNil(keychain.value(service: service, account: "tokens.alice"), "\(label): \(service)")
                }
                XCTAssertEqual(
                    keychain.value(service: userPoolService, account: "tokens.alice") == nil,
                    configuration.userPool != nil,
                    label
                )
            }
        }
    }

    /// - Given: `.default` saved, AWSMobileClient logins in the configuration's services and another identity pool's,
    ///   and a keychain listing that fails
    /// - When: `.default` is signed out
    /// - Then:
    ///    - the configuration's services are still cleared, the other identity pool's is kept, and one warning says the
    ///      listing failed, naming no one
    func testAFailedListingStillClearsTheConfigurationsServices() throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "the test host has a bundle identifier")
        let other = "\(bundle).AWSCognitoCredentialsProvider.us-east-1:other-a"
        seedLegacyLogins()
        harness.keychain.put(Data("legacy".utf8), "tokens.alice", service: other)
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        let keychain = harness.keychain
        let pools = pools
        let store = store(legacyLoginStores: {
            SessionRecordStore.legacyLoginStores(
                for: pools,
                listServices: { throw KeychainAccessError.securityError(errSecInteractionNotAllowed) },
                makeStore: { keychain.itemStore(service: $0) }
            )
        })
        let sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        defer { AmplifyLogging.removeSink(sink) }

        _ = try store.signOut(.default)

        assertLegacyLogins(present: false)
        XCTAssertNotNil(harness.keychain.value(service: other, account: "tokens.alice"))
        XCTAssertEqual(
            sink.lines(in: [ClientLog.category(ClientLog.sessionRecordStore)]),
            [SessionRecordStore.legacyLoginListingFailedWarning]
        )
    }

    // MARK: Through the client

    /// - Given: alice signed in on `.default` through the client, and AWSMobileClient logins left from an earlier release
    /// - When: she signs out
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are cleared, so a plugin build cannot migrate them back
    func testTheClientsSignOutClearsThem() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        assertLegacyLogins(present: false)
    }

    /// - Given: no saved login under `.default`, and AWSMobileClient logins left from an earlier release
    /// - When: the client signs `.default` out, with nothing to sign out
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are cleared, as the plugin's sign-out from signed out
    ///      clears them
    func testASignOutWithNoSavedLoginClearsThem() async throws {
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertNil(harness.keychain.value(pluginAccount))
        assertLegacyLogins(present: false)
    }

    /// - Given: `.default`'s saved login holding `{"noCredentials":{}}`, and AWSMobileClient logins
    /// - When: the client signs `.default` out, with nothing to sign out
    /// - Then:
    ///    - the result is `.complete`, the saved login still holds `{"noCredentials":{}}`, and the AWSMobileClient logins
    ///      are cleared
    func testASignOutOfASignedOutLoginClearsThem() async throws {
        harness.keychain.put(PluginRecordFixtures.noCredentials, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.noCredentials)
        assertLegacyLogins(present: false)
    }

    /// - Given: AWSMobileClient logins, and `.default` with no saved login, then with `{"noCredentials":{}}`
    /// - When: `signOutStoredSession(.default, configuration:)` runs each time, with nothing to sign out
    /// - Then:
    ///    - each result is `.complete`, and each time the AWSMobileClient logins are cleared
    func testAStoredSessionSignOutWithNothingToSignOutClearsThem() async throws {
        for saved in [nil, PluginRecordFixtures.noCredentials] {
            if let saved {
                harness.keychain.put(saved, pluginAccount)
            }
            seedLegacyLogins()

            let result = await AmplifyCognitoClient.signOutStoredSession(
                sessionId: .default,
                configuration: ClientFixtures.configuration,
                accessGroup: nil,
                dependencies: dependencies()
            )

            let context = saved == nil ? "no saved login" : "a signed-out saved login"
            XCTAssertEqual(result, .complete, context)
            XCTAssertEqual(harness.keychain.value(pluginAccount), saved, context)
            assertLegacyLogins(present: false, context)
        }
    }

    /// - Given: alice signed in on `.default` through the client, and AWSMobileClient logins
    /// - When: she deletes herself
    /// - Then:
    ///    - `.default`'s saved login is gone, and so are the AWSMobileClient logins
    func testDeletingTheUserClearsThem() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        try await client.deleteUser()

        XCTAssertNil(harness.keychain.value(pluginAccount))
        assertLegacyLogins(present: false)
    }

    /// - Given: a federated identity on `.default`, and AWSMobileClient logins
    /// - When: the federation is cleared
    /// - Then:
    ///    - the saved login is signed out, and the AWSMobileClient logins are cleared
    func testClearingTheFederationClearsThem() async throws {
        harness.keychain.put(FakePayload.federated().data, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        try await client.clearFederationToIdentityPool()

        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.noCredentials)
        assertLegacyLogins(present: false)
    }

    // MARK: Nothing to sign out

    /// Like the plugin's, a `.default` sign-out clears the AWSMobileClient logins even when it has nothing to sign
    /// out: otherwise a rollback to a plugin build would migrate the user back in, signed in.
    ///
    /// - Given: no saved login under `.default`, and AWSMobileClient logins left from an earlier release
    /// - When: `.default` signs out through its client
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are cleared
    func testASignOutOfAnAbsentDefaultSessionClearsThem() async throws {
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        assertLegacyLogins(present: false)
    }

    /// - Given: `.default`'s saved login signed out (`{"noCredentials":{}}`), and AWSMobileClient logins
    /// - When: `.default` signs out through its client
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are cleared
    func testASignOutOfASignedOutDefaultSessionClearsThem() async throws {
        harness.keychain.put(PluginRecordFixtures.noCredentials, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.noCredentials)
        assertLegacyLogins(present: false)
    }

    /// - Given: no saved login under `.default`, and AWSMobileClient logins
    /// - When: `signOutStoredSession(.default)` runs, with no client of it live
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are cleared
    func testAStaticSignOutOfAnAbsentDefaultSessionClearsThem() async throws {
        seedLegacyLogins()

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: dependencies()
        )

        XCTAssertEqual(result, .complete)
        assertLegacyLogins(present: false)
    }

    // MARK: Helpers

    private var services: [String] {
        SessionRecordStore.legacyLoginServices(for: pools)
    }

    private func seedLegacyLogins() {
        for service in services {
            harness.keychain.put(Data("legacy".utf8), "tokens.alice", service: service)
        }
    }

    private func assertLegacyLogins(present: Bool, _ context: String = "", file: StaticString = #filePath, line: UInt = #line) {
        for service in services {
            let value = harness.keychain.value(service: service, account: "tokens.alice")
            XCTAssertEqual(value != nil, present, "\(service) \(context)", file: file, line: line)
        }
    }

    /// A store over the harness's keychain, as `TestKeychain.recordStore(for:)` builds it, that clears `legacyLoginStores`:
    /// by default the harness's AWSMobileClient services.
    private func store(
        for namespace: SessionStorageNamespace = StorageFixtures.namespace,
        legacyLoginStores: (@Sendable () -> [any KeychainItemStoreBehavior])? = nil
    ) -> SessionRecordStore {
        Self.store(over: harness.keychain, for: namespace, legacyLoginStores: legacyLoginStores)
    }

    private static func store(
        over keychain: TestKeychain,
        for namespace: SessionStorageNamespace,
        legacyLoginStores: (@Sendable () -> [any KeychainItemStoreBehavior])? = nil
    ) -> SessionRecordStore {
        let services = SessionRecordStore.legacyLoginServices(for: namespace.pools)
        let clock = TestClock()
        return SessionRecordStore(
            namespace: namespace,
            keychain: keychain.itemStore(
                service: SessionRecordStore.service(forAccessGroup: namespace.accessGroup),
                accessGroup: namespace.accessGroup
            ),
            now: { clock.next() },
            userPoolTokensOnly: TestKeychain.userPoolTokensOnly,
            identityIdOf: TestKeychain.identityId,
            refreshTokenOf: TestKeychain.refreshToken,
            markerScope: TestKeychain.markerScope,
            summarizeSharedRecord: TestKeychain.summarizeSharedRecord,
            rereadsAbsentSharedRecord: false,
            sameCredentials: TestKeychain.sameCredentials,
            legacyLoginStores: legacyLoginStores ?? { services.map { keychain.itemStore(service: $0) } }
        )
    }

    private func defaultClient() throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: .default),
            dependencies: dependencies()
        )
    }

    /// The harness's dependencies, with stores that clear the harness's AWSMobileClient services.
    private func dependencies() -> SessionCoreDependencies {
        let base = harness.dependencies
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: { [keychain = harness.keychain] in Self.store(over: keychain, for: $0) },
            makeClients: base.makeClients,
            makeEngine: base.makeEngine,
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        dependencies.makePreviousConfigurationRevoker = base.makePreviousConfigurationRevoker
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = base.sheetLock
        #endif
        return dependencies
    }
}

/// What the saved login held each time an AWSMobileClient service was cleared. Shared with
/// `DefaultSessionGuestLegacyLoginTests`.
final class ClearOrder: @unchecked Sendable {
    // `@unchecked Sendable`: `seen` is only touched while holding `lock`.
    private let lock = NSLock()
    private var seen: [Data?] = []

    var savedLoginsSeen: [Data?] {
        lock.lock()
        defer { lock.unlock() }
        return seen
    }

    func record(cleared savedLogin: Data?) {
        lock.lock()
        defer { lock.unlock() }
        seen.append(savedLogin)
    }
}

/// An item store that calls `onRemoveAll` before it clears `base`, and otherwise is `base`. Shared with
/// `DefaultSessionGuestLegacyLoginTests`.
struct ObservedItemStore: KeychainItemStoreBehavior {
    let base: any KeychainItemStoreBehavior
    let onRemoveAll: @Sendable () -> Void

    init(_ base: any KeychainItemStoreBehavior, onRemoveAll: @escaping @Sendable () -> Void) {
        self.base = base
        self.onRemoveAll = onRemoveAll
    }

    func getData(_ key: String) throws -> Data { try base.getData(key) }
    func set(_ value: Data, key: String) throws { try base.set(value, key: key) }
    func addIfAbsent(_ value: Data, key: String) throws -> Bool { try base.addIfAbsent(value, key: key) }
    func replaceIfPresent(_ value: Data, key: String) throws -> Bool { try base.replaceIfPresent(value, key: key) }
    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    func remove(_ key: String) throws { try base.remove(key) }
    func remove(_ entry: KeychainEntry) throws { try base.remove(entry) }
    func removeAll() throws {
        onRemoveAll()
        try base.removeAll()
    }

    func hasItems() throws -> Bool { try base.hasItems() }
    func allAccounts() throws -> [String] { try base.allAccounts() }
    func allEntries() throws -> [KeychainEntry] { try base.allEntries() }
}

/// An item store whose `removeAll` fails, and that holds nothing otherwise.
private struct UnclearableItemStore: KeychainItemStoreBehavior {
    func getData(_ key: String) throws -> Data { throw KeychainAccessError.itemNotFound }
    func set(_ value: Data, key: String) throws {}
    func addIfAbsent(_ value: Data, key: String) throws -> Bool { true }
    func replaceIfPresent(_ value: Data, key: String) throws -> Bool { false }
    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome { .notFound }
    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome { .notFound }
    func remove(_ key: String) throws {}
    func remove(_ entry: KeychainEntry) throws {}
    func removeAll() throws { throw KeychainAccessError.securityError(errSecInteractionNotAllowed) }
    func hasItems() throws -> Bool { false }
    func allAccounts() throws -> [String] { [] }
    func allEntries() throws -> [KeychainEntry] { [] }
}
