//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// What a plugin release from before the forward-compatible reader can see of the keychain:
/// everything except the Cognito client's records.
///
/// A released binary cannot run in this process. It never looks at an `amplify.<digits>.` account, and
/// every behaviour the reader added depends on reading one: the fallback read in `retrieveCredential()`, and the
/// signed-out marker written by `removeSession` when a client record exists. So on the paths these tests
/// run, the current credential store over this view does what the released store did: retrieve, save and
/// delete touch only its own key, with a plain delete at sign-out, and the configuration-change handling is
/// the released one. Those paths are otherwise unchanged since that release, and the stored-format goldens
/// pin what they store. The access-group handling at construction is not emulated: the test seam skips
/// it, and there the released store differs (it still calls a service-wide `_removeAll()`, since scoped).
///
/// Hidden accounts read as "no item". A write or delete of one would be a bug in the emulation, so the
/// tests assert there are none.
final class ReleasedPluginKeychainView: KeychainItemStoreBehavior, @unchecked Sendable {

    private let base: InMemoryPluginKeychainStore

    init(_ base: InMemoryPluginKeychainStore) {
        self.base = base
    }

    /// Whether `account` is one of the Cognito client's records, which a pre-reader release never reads.
    static func isHidden(_ account: String) -> Bool {
        SessionRecordAccount.isClientSessionRecord(account)
    }

    func getData(_ key: String) throws -> Data {
        guard !Self.isHidden(key) else {
            throw KeychainAccessError.itemNotFound
        }
        return try base.getData(key)
    }

    func set(_ value: Data, key: String) throws {
        try base.set(value, key: key)
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try base.addIfAbsent(value, key: key)
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try base.replaceIfPresent(value, key: key)
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    func remove(_ key: String) throws {
        try base.remove(key)
    }

    func remove(_ entry: KeychainEntry) throws {
        try base.remove(entry)
    }

    func removeAll() throws {
        try base.removeAll()
    }

    func hasItems() throws -> Bool {
        try base.hasItems()
    }

    func allAccounts() throws -> [String] {
        try base.allAccounts().filter { !Self.isHidden($0) }
    }

    func allEntries() throws -> [KeychainEntry] {
        try base.allEntries().filter { !Self.isHidden($0.account) }
    }
}

/// The two plugin binaries a rollback can land on, as the columns of the rollback matrix name them.
enum RollbackPluginBinary: String, CaseIterable {
    /// A plugin release from before the forward-compatible reader, emulated by `ReleasedPluginKeychainView`.
    case old
    /// This plugin: the forward-compatible reader.
    case reader

    func keychainStore(over pluginKeychain: InMemoryPluginKeychainStore) -> any KeychainItemStoreBehavior {
        switch self {
        case .old: return ReleasedPluginKeychainView(pluginKeychain)
        case .reader: return pluginKeychain
        }
    }
}

/// The stored bytes the rollback matrix is built from. The client's records are written by the client's own
/// store, so they are its exact bytes. The plugin's come from its frozen fixtures, whose JSON is canonical
/// (key-sorted) rather than the key order the plugin's unsorted encoder happens to produce; every reader
/// decodes both the same.
enum RollbackMatrixBytes {

    /// A payload the plugin wrote, from the frozen payload fixtures
    /// (`TestResources/amplifyCredentials/<case>.payload.json`). Tokens valid until 2033.
    static func pluginPayload(_ caseName: String) throws -> Data {
        try AmplifyCredentialsPayloadFixtures.data(caseName)
    }

    /// A session record the plugin wrote, from the stored-format goldens
    /// (`TestResources/GoldenStoredFormat/<name>.json`), without the file's trailing newline. The tokens in
    /// these expired in 2023, so reading one refreshes.
    static func goldenSession(_ name: String) throws -> Data {
        var data = try Data(contentsOf: GoldenFiles.directory("GoldenStoredFormat").appendingPathComponent("\(name).json"))
        if data.last == UInt8(ascii: "\n") {
            data.removeLast()
        }
        return data
    }

    /// `payload` with its one refresh token replaced by `refreshToken`: the same JSON with one value changed,
    /// as a refresh that rotated the token leaves it.
    static func replacingRefreshToken(in payload: Data, with refreshToken: String) throws -> Data {
        let marker = #""refreshToken":""#
        guard let parts = String(bytes: payload, encoding: .utf8)?.components(separatedBy: marker),
              parts.count == 2, let end = parts[1].firstIndex(of: "\"") else {
            throw CocoaError(.coderInvalidValue)
        }
        return Data((parts[0] + marker + refreshToken + parts[1][end...]).utf8)
    }

    /// The plugin's signed-out marker, `{"noCredentials":{}}`, as its encoder writes it.
    static func signedOutMarker() throws -> Data {
        try pluginPayload("noCredentials")
    }

    /// The fixed instant the client's record store stamps records with here, so the bytes are the same every run.
    static let clientWriteTime = Date(timeIntervalSince1970: 1_790_000_000)

    /// Writes `payload` as a signed-in record of `sessionId`, through the client's own record store, as the
    /// client stores a session it signed in or adopted: the payload verbatim, with its kind, user name and
    /// user ID. Returns the bytes stored, and clears the keychain's mutation log.
    @discardableResult
    static func writeClientRecord(
        _ payload: Data,
        for sessionId: SessionID = .default,
        label: String? = nil,
        in keychain: InMemoryKeychain,
        pools: PoolNamespace
    ) throws -> Data {
        let summary = PluginRecordSummary.peek(payload)
        let record = SessionRecord(
            label: label,
            username: summary.username,
            userId: summary.userId,
            kind: summary.kind,
            credentials: payload
        )
        let store = clientStore(in: keychain, pools: pools)
        guard try store.write(record, for: sessionId, expecting: nil).didCommit else {
            throw CocoaError(.fileWriteFileExists)
        }
        keychain.resetMutations()
        return try XCTUnwrap(keychain.value(service: pluginKeychainService, account: store.sessionAccount(for: sessionId)))
    }

    /// Signs `sessionId` out through the client's own record store, which keeps the row with no credentials
    /// and, for `.default`, deletes the plugin's record. Returns the bytes stored, and clears the mutation log.
    @discardableResult
    static func signOutClientRecord(
        _ sessionId: SessionID = .default,
        in keychain: InMemoryKeychain,
        pools: PoolNamespace
    ) throws -> Data {
        let store = clientStore(in: keychain, pools: pools)
        _ = try store.signOut(sessionId)
        keychain.resetMutations()
        return try XCTUnwrap(keychain.value(service: pluginKeychainService, account: store.sessionAccount(for: sessionId)))
    }

    /// The client's record store over `keychain`, with its clock fixed at `clientWriteTime`.
    static func clientStore(in keychain: InMemoryKeychain, pools: PoolNamespace) -> SessionRecordStore {
        SessionRecordStore(
            namespace: SessionStorageNamespace(pools: pools, accessGroup: nil),
            keychain: keychain.store(service: SessionRecordStore.unsharedService),
            now: { clientWriteTime }
        )
    }

    /// Puts `data` under `account` in the plugin's service, as another binary left it, and clears the
    /// mutation log.
    static func put(_ data: Data, _ account: String, in keychain: InMemoryKeychain) throws {
        try keychain.store(service: pluginKeychainService).set(data, key: account)
        keychain.resetMutations()
    }
}

extension XCTestCase {

    /// A plugin as `configure(using:)` builds it, except that its credential store runs over `keychainStore`
    /// and the Cognito service calls are mocked.
    func makePluginOverKeychain(
        _ keychainStore: any KeychainItemStoreBehavior,
        authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData(),
        userPool: CognitoUserPoolBehavior
    ) -> AWSCognitoAuthPlugin {
        let credentialStoreMachine = CredentialStoreStateMachine(
            resolver: CredentialStoreState.Resolver(),
            environment: CredentialEnvironment(
                authConfiguration: authConfiguration,
                credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                    amplifyCredentialStoreFactory: {
                        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration, keychain: keychainStore)
                    },
                    legacyKeychainStoreFactory: Defaults.makeLegacyStore(service:)
                ),
                logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
            ),
            initialState: .idle
        )
        let identity = MockIdentity(
            mockGetIdResponse: { _ in .init(identityId: "client-identity-id") },
            mockGetCredentialsResponse: { _ in
                .init(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: "refreshedAccessKey",
                        expiration: Date(timeIntervalSinceNow: 3_600),
                        secretKey: "refreshedSecret",
                        sessionToken: "refreshedSession"
                    ),
                    identityId: "client-identity-id"
                )
            }
        )
        let defaults = Defaults.makeDefaultAuthEnvironment(identityPoolFactory: { identity }, userPoolFactory: { userPool })
        let authEnvironment = AuthEnvironment(
            configuration: defaults.configuration,
            userPoolConfigData: defaults.userPoolConfigData,
            identityPoolConfigData: defaults.identityPoolConfigData,
            authenticationEnvironment: defaults.authenticationEnvironment,
            authorizationEnvironment: defaults.authorizationEnvironment,
            credentialsClient: CredentialStoreOperationClient(credentialStoreStateMachine: credentialStoreMachine),
            logger: defaults.logger
        )
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: AuthStateMachine(resolver: AuthState.Resolver(), environment: authEnvironment),
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        settleConfigureOperationOnTeardown(of: plugin)
        return plugin
    }
}
