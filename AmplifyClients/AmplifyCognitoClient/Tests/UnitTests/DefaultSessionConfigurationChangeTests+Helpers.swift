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

/// The fixtures every `DefaultSessionConfigurationChangeTests` file shares.
extension DefaultSessionConfigurationChangeTests {

    // MARK: - Helpers

    var pluginKeychain: any KeychainItemStoreBehavior {
        harness.keychain.itemStore(service: SessionRecordStore.unsharedService)
    }

    func account(_ configuration: AuthClientConfiguration) -> String {
        SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
    }

    /// The plugin's credential store, built with `configuration` over the harness's keychain: it runs its own rule.
    @discardableResult
    func pluginStore(_ configuration: AuthClientConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(authConfiguration: AuthConfiguration(client: configuration), keychain: pluginKeychain, logger: DiscardingEngineLogger())
    }

    /// The plugin, built with `configuration`, saves `payload`; returns the bytes it stored. The logs are cleared.
    @discardableResult
    func pluginSaves(_ payload: Data, under configuration: AuthClientConfiguration) throws -> Data {
        try pluginSaves(payload, under: AuthConfiguration(client: configuration))
    }

    @discardableResult
    func pluginSaves(_ payload: Data, under configuration: AuthConfiguration) throws -> Data {
        let store = AWSCognitoAuthCredentialStore(authConfiguration: configuration, keychain: pluginKeychain, logger: DiscardingEngineLogger())
        try store.saveCredential(AmplifyCredentials.decoded(payload))
        harness.keychain.resetLogs()
        return try XCTUnwrap(harness.keychain.value(AWSCognitoAuthCredentialStore.sessionAccount(for: configuration)))
    }

    /// `username` signed in through the live engine under `configuration`, then saved by the plugin built with it.
    @discardableResult
    func pluginSignsIn(_ username: String, under configuration: AuthClientConfiguration) async throws -> Data {
        try await pluginSaves(signedInPayload(username, under: configuration), under: configuration)
    }

    func signedInPayload(_ username: String, under configuration: AuthClientConfiguration) async throws -> Data {
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

    func listed(_ configuration: AuthClientConfiguration, includingSignedOut: Bool = false) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: configuration,
            accessGroup: nil,
            includingSignedOut: includingSignedOut,
            dependencies: dependencies
        )
    }

    /// Lets any revoke a restore started run: none is awaited by the restore.
    func settleRevokes() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: The client

    func makeClient(_ configuration: AuthClientConfiguration, _ sessionId: SessionID = .default) -> AmplifyCognitoClient {
        do {
            return try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId), dependencies: dependencies)
        } catch {
            preconditionFailure("the client could not be built: \(error)")
        }
    }

    /// The harness's dependencies, with the live engine over scripted Cognito for each session's configuration, and
    /// a previous configuration's revoker over the same scripted Cognito, recording the configuration it was built for.
    var dependencies: SessionCoreDependencies {
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

    static func liveEngine(
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

    func scriptSRP(_ username: String = "alice") {
        cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier(username) }
        cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn(username) }
    }

    func scriptIdentityPool(identityId: String = LiveEngineFixtures.identityId, version: Int = 1) {
        cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: identityId) }
        cognito.always("GetCredentialsForIdentity") { (input: GetCredentialsForIdentityInput) in
            GetCredentialsForIdentityOutput(credentials: LiveEngineFixtures.awsCredentials(version: version), identityId: input.identityId)
        }
    }

    func scriptRefresh(_ username: String = "alice", version: Int) {
        cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: version))
        }
    }
}

/// The configurations each previous configuration's revoker was built for, in order.
final class PreviousConfigurationRevokers: @unchecked Sendable {
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
