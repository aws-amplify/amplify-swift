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

    /// An item the plugin wrote, from the stored-format goldens (`TestResources/GoldenStoredFormat/<name>.json`),
    /// without the file's trailing newline: a session record, or an `authConfiguration`. The tokens in the session
    /// records expired in 2023, so reading one refreshes.
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

    /// The fixed instant the client's record store stamps records with here, so the bytes are the same every run.
    static let clientWriteTime = Date(timeIntervalSince1970: 1_790_000_000)

    /// Writes `payload` as a signed-in record of `sessionId`, through the client's own record store, as the
    /// client stores a session it signed in: the payload verbatim, with its kind, user name and user ID; for
    /// `.default`, the payload itself under the plugin's own account, with the sidecar. Returns the bytes stored,
    /// and clears the keychain's mutation log.
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

    /// Puts `payload` under `amplify.1.<ns>.$default.session` as a signed-in envelope, the record a development
    /// build of the client kept for `.default` before it used the plugin's own record.
    /// Nothing reads it now. Returns the bytes stored, and clears the mutation log.
    @discardableResult
    static func writeLeftoverDefaultRecord(_ payload: Data, in keychain: InMemoryKeychain, pools: PoolNamespace) throws -> Data {
        let summary = PluginRecordSummary.peek(payload)
        let record = SessionRecord(
            label: nil,
            username: summary.username,
            userId: summary.userId,
            kind: summary.kind,
            credentials: payload
        )
        let data = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: clientWriteTime, record: record).encoded()
        try put(data, SessionRecordKey.account(for: .default, in: pools, kind: .session), in: keychain)
        return data
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
                        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration, keychain: keychainStore, logger: AmplifyEngineLogRouter())
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
            authStateMachine: AuthStateMachine(resolver: AuthState.Resolver(logger: AmplifyEngineLogRouter()), environment: authEnvironment),
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        settleConfigureOperationOnTeardown(of: plugin)
        return plugin
    }
}
