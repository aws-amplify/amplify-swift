//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import InternalAmplifyKeychain
import Security
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.

/// Covers the interaction between the legacy credential migration and clearing the credential store on
/// sign-out: legacy stores kept for a later migration must not bring a session back after sign-out.
class LegacyCredentialStoreSignOutTests: XCTestCase, @unchecked Sendable {

    private let authConfiguration = AuthConfiguration.userPoolsAndIdentityPools(
        Defaults.makeDefaultUserPoolConfigData(),
        Defaults.makeIdentityConfigData()
    )

    /// Test that an explicit sign-out sticks even when legacy credentials were kept for a later migration
    ///
    /// - Given: Legacy stores holding a legacy session that cannot be read at launch (for example while
    ///   the device is locked), so the migration keeps them
    /// - When:
    ///    - The user signs in, then signs out, and a later launch runs the migration with the legacy
    ///      stores readable again
    /// - Then:
    ///    - Signing out clears the legacy stores, so the later migration finds nothing and the user
    ///      stays signed out
    ///
    func testSignOut_afterLegacyStoresWereKept_shouldPreventLegacySessionFromComingBack() async throws {
        let legacyKeychain = InMemoryLegacyKeychain(populatedServices: legacyServices())
        legacyKeychain.readError = EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        let credentialStore = InMemoryCredentialStore()
        let environment = makeEnvironment(legacyKeychain: legacyKeychain, credentialStore: credentialStore)

        // Launch while the legacy stores cannot be read: they are kept.
        await MigrateLegacyCredentialStore().execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
        XCTAssertNil(credentialStore.credentials)
        XCTAssertEqual(legacyKeychain.populatedServices, Set(legacyServices()))

        // The user signs in, then signs out.
        try credentialStore.store.saveCredential(AmplifyCredentials.testData)
        let cleared = expectation(description: "credentialCleared")
        await ClearCredentialStore(dataStoreType: .amplifyCredentials).execute(
            withDispatcher: MockDispatcher { event in
                if let event = event as? CredentialStoreEvent,
                   case .credentialCleared(.amplifyCredentials) = event.eventType {
                    cleared.fulfill()
                }
            },
            environment: environment
        )
        await fulfillment(of: [cleared], timeout: 1)
        XCTAssertNil(credentialStore.credentials)
        XCTAssertTrue(legacyKeychain.populatedServices.isEmpty, "Sign-out left legacy stores behind")

        // A later launch, with the keychain readable again, has nothing to bring back.
        legacyKeychain.readError = nil
        await MigrateLegacyCredentialStore().execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
        XCTAssertNil(credentialStore.credentials, "The legacy session came back after sign-out")
    }

    /// Test that sign-out still succeeds when a legacy store cannot be cleared
    ///
    /// - Given: A signed-in session, and legacy stores whose removal fails with a keychain error
    /// - When:
    ///    - The credential store is cleared on sign-out
    /// - Then:
    ///    - The session is deleted and `.credentialCleared(.amplifyCredentials)` is dispatched, with no error
    ///
    /// The action dispatches before `execute` returns and starts no task, so the test checks the recorded
    /// events once it returns, rather than waiting on an inverted expectation that can only time out
    /// (see `MigrateLegacyCredentialStoreTests.testExecute_whenSavingMigratedCredentialsFails_shouldKeepLegacyStores`).
    ///
    func testSignOut_whenClearingLegacyStoreFails_shouldStillSucceed() async throws {
        let legacyKeychain = InMemoryLegacyKeychain(populatedServices: legacyServices())
        legacyKeychain.removeAllError = EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        let credentialStore = InMemoryCredentialStore()
        try credentialStore.store.saveCredential(AmplifyCredentials.testData)

        let dispatchedEvents = TestBox<[CredentialStoreEvent.EventType]>([])
        await ClearCredentialStore(dataStoreType: .amplifyCredentials).execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? CredentialStoreEvent else { return }
                dispatchedEvents.with { $0.append(event.eventType) }
            },
            environment: makeEnvironment(legacyKeychain: legacyKeychain, credentialStore: credentialStore)
        )
        XCTAssertEqual(dispatchedEvents.get(), [.credentialCleared(.amplifyCredentials)])
        XCTAssertNil(credentialStore.credentials)
        XCTAssertEqual(legacyKeychain.removeAllCount, legacyServices().count, "Every legacy store should be attempted")
    }

    /// Test that the legacy stores are left alone when the session itself could not be cleared
    ///
    /// - Given: Legacy stores, and a credential store whose delete fails with a keychain error
    /// - When:
    ///    - The credential store is cleared on sign-out
    /// - Then:
    ///    - The delete error is dispatched exactly as before, and the legacy stores are not cleared
    ///
    func testSignOut_whenDeletingSessionFails_shouldNotClearLegacyStores() async {
        let legacyKeychain = InMemoryLegacyKeychain(populatedServices: legacyServices())
        let deleteError = EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        let store = MockAmplifyCredentialStoreBehavior(clearCredentialHandler: { throw deleteError })

        let failed = expectation(description: "throwError")
        await ClearCredentialStore(dataStoreType: .amplifyCredentials).execute(
            withDispatcher: MockDispatcher { event in
                if let event = event as? CredentialStoreEvent, case .throwError(let error) = event.eventType {
                    XCTAssertEqual(error, deleteError)
                    failed.fulfill()
                }
            },
            environment: makeEnvironment(legacyKeychain: legacyKeychain, amplifyCredentialStore: store)
        )
        await fulfillment(of: [failed], timeout: 0.1)
        XCTAssertEqual(legacyKeychain.removeAllCount, 0)
        XCTAssertEqual(legacyKeychain.populatedServices, Set(legacyServices()))
    }

    /// Test that clearing device records does not touch the legacy stores
    ///
    /// - Given: Legacy stores
    /// - When:
    ///    - Device metadata and the ASF device id are cleared
    /// - Then:
    ///    - The legacy stores are not cleared
    ///
    func testClearingDeviceRecords_shouldNotClearLegacyStores() async {
        let legacyKeychain = InMemoryLegacyKeychain(populatedServices: legacyServices())
        let environment = makeEnvironment(
            legacyKeychain: legacyKeychain,
            amplifyCredentialStore: MockAmplifyCredentialStoreBehavior()
        )
        await ClearCredentialStore(dataStoreType: .deviceMetadata(username: "user"))
            .execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
        await ClearCredentialStore(dataStoreType: .asfDeviceId(username: "user"))
            .execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
        XCTAssertEqual(legacyKeychain.removeAllCount, 0)
    }

    /// Test that sign-out clears exactly the legacy stores the migration reads
    ///
    /// - Given: Each kind of auth configuration
    /// - When:
    ///    - The migration runs against a keychain that records which services are opened
    /// - Then:
    ///    - The services it opens are exactly `MigrateLegacyCredentialStore.legacyServiceKeys(for:)`, which
    ///      sign-out clears
    ///
    func testLegacyServiceKeys_matchTheServicesTheMigrationReads() async {
        let configurations: [AuthConfiguration] = [
            .userPools(Defaults.makeDefaultUserPoolConfigData()),
            .identityPools(Defaults.makeIdentityConfigData()),
            authConfiguration
        ]
        for configuration in configurations {
            let legacyKeychain = InMemoryLegacyKeychain(populatedServices: [])
            let environment = makeEnvironment(
                legacyKeychain: legacyKeychain,
                amplifyCredentialStore: MockAmplifyCredentialStoreBehavior(),
                authConfiguration: configuration
            )
            await MigrateLegacyCredentialStore().execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
            XCTAssertEqual(
                legacyKeychain.openedServices,
                Set(MigrateLegacyCredentialStore.legacyServiceKeys(for: configuration)),
                "Mismatch for \(configuration)"
            )
        }
    }

    // MARK: - Helpers

    private func legacyServices() -> [String] {
        MigrateLegacyCredentialStore.legacyServiceKeys(for: authConfiguration)
    }

    private func makeEnvironment(
        legacyKeychain: InMemoryLegacyKeychain,
        credentialStore: InMemoryCredentialStore
    ) -> CredentialEnvironment {
        makeEnvironment(legacyKeychain: legacyKeychain, amplifyCredentialStore: credentialStore.store)
    }

    private func makeEnvironment(
        legacyKeychain: InMemoryLegacyKeychain,
        amplifyCredentialStore: MockAmplifyCredentialStoreBehavior,
        authConfiguration: AuthConfiguration? = nil
    ) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: authConfiguration ?? self.authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: { amplifyCredentialStore },
                legacyKeychainStoreFactory: { service in legacyKeychain.store(for: service) }
            ),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )
    }
}

/// A credential store that keeps one session in memory.
private final class InMemoryCredentialStore: @unchecked Sendable {
    var credentials: AmplifyCredentials?

    lazy var store = MockAmplifyCredentialStoreBehavior(
        saveCredentialHandler: { [unowned self] credentials in
            self.credentials = credentials as? AmplifyCredentials
        },
        getCredentialHandler: { [unowned self] in
            guard let credentials else {
                throw EngineCredentialStoreError.itemNotFound
            }
            return credentials
        },
        clearCredentialHandler: { [unowned self] in
            credentials = nil
        }
    )
}

/// Legacy keychain services held in memory. A populated service returns a value for every key;
/// an empty one throws `itemNotFound`.
private final class InMemoryLegacyKeychain: @unchecked Sendable {
    private(set) var populatedServices: Set<String>
    private(set) var openedServices: Set<String> = []
    private(set) var removeAllCount = 0
    var readError: Error?
    var removeAllError: Error?

    init(populatedServices: [String]) {
        self.populatedServices = Set(populatedServices)
    }

    func store(for service: String) -> any KeychainItemStoreBehavior {
        openedServices.insert(service)
        return Store(keychain: self, service: service)
    }

    fileprivate func read(_ service: String) throws -> String {
        if let readError {
            throw readError
        }
        guard populatedServices.contains(service) else {
            throw EngineCredentialStoreError.itemNotFound
        }
        return "mock"
    }

    fileprivate func removeAll(_ service: String) throws {
        removeAllCount += 1
        if let removeAllError {
            throw removeAllError
        }
        populatedServices.remove(service)
    }

    fileprivate func hasItems(_ service: String) -> Bool {
        populatedServices.contains(service)
    }

    private struct Store: LegacyKeychainItemStoreDouble, @unchecked Sendable {
        let keychain: InMemoryLegacyKeychain
        let service: String

        func getData(_ key: String) throws -> Data {
            try Data(keychain.read(service).utf8)
        }

        func set(_ value: Data, key: String) throws { }

        func remove(_ key: String) throws { }

        func removeAll() throws {
            try keychain.removeAll(service)
        }

        func hasItems() throws -> Bool {
            keychain.hasItems(service)
        }
    }
}
