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
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The Cognito client as an app runs it, over the rollback matrix's shared in-memory keychain: real
/// `AmplifyCognitoClient`s, with their own registry and gate table, the client's real record store, and its live
/// engine (the plugin's state machines) over Cognito scripted with the plugin's own mocks.
///
/// Script Cognito (`script(userPool:identity:)`) before making a client: each client's engine is built with the
/// script in place when it is made. A row "relaunches" by dropping its clients and awaiting `waitForBaseline()`.
///
/// - Note: `@unchecked Sendable`: `userPool` and `identity` are only touched while holding `lock`.
final class ClientOverKeychain: @unchecked Sendable {

    /// Both pools, with IDs and an app client whose plugin configuration is `ConfigurationChangeCase.both()`, so a
    /// plugin store built with `AuthConfiguration(client:)` of it is the same app's plugin build.
    static let configuration = makeConfiguration(userPool: true, identityPool: true)
    /// The same user pool and app client alone: `ConfigurationChangeCase.userPool()`.
    static let userPoolOnlyConfiguration = makeConfiguration(userPool: true, identityPool: false)
    /// The same identity pool alone: `ConfigurationChangeCase.identityPool()`.
    static let identityPoolOnlyConfiguration = makeConfiguration(userPool: false, identityPool: true)

    /// The identity ID the scripted identity pool gives every login.
    static let identityId = "us-east-1:client-over-keychain-identity"

    let keychain: InMemoryKeychain
    let registry = SessionCoreDependencies.Registry()
    let gates = SessionRecordGates()

    private let lock = NSLock()
    private var userPool = MockIdentityProvider()
    private var identity = ClientOverKeychain.identityPool()

    init(keychain: InMemoryKeychain) {
        self.keychain = keychain
    }

    /// The Cognito calls of the clients made from now on.
    func script(userPool: MockIdentityProvider, identity: MockIdentity = ClientOverKeychain.identityPool()) {
        lock.withLock {
            self.userPool = userPool
            self.identity = identity
        }
    }

    /// A client of `sessionId`, as an app builds it with `configuration`.
    func client(
        _ sessionId: SessionID = .default,
        configuration: AuthClientConfiguration = ClientOverKeychain.configuration
    ) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId), dependencies: dependencies)
    }

    /// The saved sessions `AmplifyCognitoClient.storedSessions` lists for `configuration`.
    func storedSessions(
        configuration: AuthClientConfiguration = ClientOverKeychain.configuration,
        includingSignedOut: Bool = false
    ) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: configuration,
            accessGroup: nil,
            includingSignedOut: includingSignedOut,
            dependencies: dependencies
        )
    }

    /// Waits until every client made here is released and its core pruned: the app has quit.
    func waitForBaseline(file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0 ..< 500 {
            if registry.entryCount == 0, gates.liveGateCount == 0 {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("the clients' cores were not released", file: file, line: line)
    }

    var dependencies: SessionCoreDependencies {
        let keychain = keychain
        return SessionCoreDependencies(
            registry: registry,
            gates: gates,
            makeStore: { namespace in
                SessionRecordStore(
                    namespace: namespace,
                    keychain: keychain.store(service: SessionRecordStore.service(forAccessGroup: namespace.accessGroup))
                )
            },
            makeClients: { try CognitoServiceClients(configuration: $0, configureUserPoolClient: $1) },
            makeEngine: { [self] context in
                let (userPool, identity) = lock.withLock { (self.userPool, self.identity) }
                let authConfiguration = AuthConfiguration(client: context.configuration)
                return LiveSessionEngine(resources: EngineResources(
                    authConfiguration: authConfiguration,
                    clients: context.clients,
                    devices: DeviceRecordIO(store: DeviceRecordStore(
                        namespace: context.namespace,
                        keychain: keychain.store(service: SessionRecordStore.service(forAccessGroup: context.namespace.accessGroup))
                    )),
                    analytics: LazyUserPoolAnalytics(
                        pinpointAppId: nil,
                        keychain: keychain.store(service: LazyUserPoolAnalytics.pinpointContextService)
                    ),
                    services: EngineServices(
                        userPool: context.configuration.userPool == nil ? nil : userPool,
                        identity: context.configuration.identityPool == nil ? nil : identity
                    ),
                    makeAdvancedSecurity: FixedDeviceASF.factory
                ))
            },
            makeRevoker: { _ in InertSessionRevoker() },
            scheduleRestore: { _ in },
            bounds: .init(restoreNanoseconds: 60_000_000_000),
            now: { Date() }
        )
    }

    // MARK: Scripts

    /// Cognito's user pool for the client: `USER_PASSWORD_AUTH` signs `username` in, if given; `refresh` answers
    /// `GetTokensFromRefreshToken`; revoking and global sign-out succeed.
    static func userPool(
        signingIn username: String? = nil,
        refresh: MockIdentityProvider.MockGetTokensFromRefreshTokenResponse? = nil
    ) -> MockIdentityProvider {
        var signIn: MockIdentityProvider.MockInitiateAuthResponse?
        if let username {
            signIn = { @Sendable _ in InitiateAuthOutput(authenticationResult: ClientOverKeychain.authenticationResult(username: username)) }
        }
        return MockIdentityProvider(
            mockRevokeTokenResponse: { _ in RevokeTokenOutput() },
            mockInitiateAuthResponse: signIn,
            mockGetTokensFromRefreshTokenResponse: refresh,
            mockGlobalSignOutResponse: { _ in GlobalSignOutOutput() }
        )
    }

    /// Cognito's identity pool: every login gets `identityId`, and AWS credentials valid for an hour.
    static func identityPool() -> MockIdentity {
        MockIdentity(
            mockGetIdResponse: { _ in GetIdOutput(identityId: identityId) },
            mockGetCredentialsResponse: { input in
                GetCredentialsForIdentityOutput(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: "clientOverKeychainAccessKey",
                        expiration: Date(timeIntervalSinceNow: 3_600),
                        secretKey: "clientOverKeychainSecret",
                        sessionToken: "clientOverKeychainSession"
                    ),
                    identityId: input.identityId
                )
            }
        )
    }

    /// Tokens for `username` (`sub` `<username>-sub`) valid for an hour, with `refreshToken`
    /// (`refresh-<username>` by default).
    static func authenticationResult(
        username: String,
        refreshToken: String? = nil
    ) -> CognitoIdentityProviderClientTypes.AuthenticationResultType {
        let tokens = LongLivedCredentials.tokens(username: username, sub: "\(username)-sub")
        return .init(
            accessToken: tokens.accessToken,
            expiresIn: 3_600,
            idToken: tokens.idToken,
            refreshToken: refreshToken ?? tokens.refreshToken
        )
    }

    private static func makeConfiguration(userPool: Bool, identityPool: Bool) -> AuthClientConfiguration {
        do {
            return try AuthClientConfiguration(
                userPool: userPool
                    ? .init(poolId: ConfigurationChangeCase.userPoolId, appClientId: "client-1", region: "us-east-1")
                    : nil,
                identityPool: identityPool ? .init(poolId: ConfigurationChangeCase.identityPoolId, region: "us-east-1") : nil
            )
        } catch {
            preconditionFailure("the fixture configuration is valid: \(error)")
        }
    }
}

/// Cognito's side of refresh-token rotation for one login, shared by every binary a row runs: the one refresh token
/// it accepts now. A refresh with it succeeds and rotates it; a refresh with any other is refused with
/// `RefreshTokenReuseException`, as Cognito refuses a refresh token rotated away.
///
/// - Note: `@unchecked Sendable`: the properties below are only touched while holding `lock`.
final class RotatingRefreshTokens: @unchecked Sendable {

    private let lock = NSLock()
    private var live: String
    private var sentTokens: [String] = []
    private var refusedTokens: [String] = []

    init(live: String) {
        self.live = live
    }

    /// Every refresh token sent, in order.
    var sent: [String] {
        lock.withLock { sentTokens }
    }

    /// Every refresh token refused, in order.
    var refused: [String] {
        lock.withLock { refusedTokens }
    }

    /// Answers a refresh of `username`'s login, rotating the live token to `next`.
    func refresh(_ input: GetTokensFromRefreshTokenInput, username: String, rotatingTo next: String) throws -> GetTokensFromRefreshTokenOutput {
        try lock.withLock {
            let token = input.refreshToken ?? ""
            sentTokens.append(token)
            guard token == live else {
                refusedTokens.append(token)
                throw AWSCognitoIdentityProvider.RefreshTokenReuseException(message: "Refresh token has been used")
            }
            live = next
        }
        return GetTokensFromRefreshTokenOutput(authenticationResult: ClientOverKeychain.authenticationResult(username: username, refreshToken: next))
    }
}

extension AmplifyCredentials {

    /// The user pool refresh token this login holds, if any.
    var refreshToken: String? {
        switch self {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            return signedInData.cognitoUserPoolTokens.refreshToken
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return nil
        }
    }
}
