//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// What one session's engine is built from, once, when its core is. Pure values and SDK
/// clients: building it does no I/O, so it is safe under the registry lock.
///
/// Everything here is shared by every operation of the session: the engine configuration, the SDK clients
/// the escape hatches return, the per-user device records, the one analytics instance, and the logger. What
/// is per operation (the credential slot, the environments and the state machines) comes from
/// `makeOperation(seed:)`.
struct EngineResources: Sendable {

    /// The engine's configuration, built from the client's by a 1:1 map (`AuthConfiguration(client:)`).
    let authConfiguration: AuthConfiguration
    /// The session's SDK clients: the same instances the escape hatches return (`===`).
    let clients: CognitoServiceClients
    /// The per-user device and advanced-security records, at the plugin's keys, off the cooperative pool.
    let devices: DeviceRecordIO
    /// The one analytics instance of this engine. The engine asks for it on every user-pool request, so it is
    /// never rebuilt per call: its lookup runs at most once.
    let analytics: LazyUserPoolAnalytics
    let logger: ClientEngineLogger
    /// What the engine calls Cognito through. The session's SDK clients, unless a test replaces them with
    /// scripted `CognitoUserPoolBehavior` / `CognitoIdentityBehavior` doubles.
    let services: EngineServices
    /// Makes the hosted UI's browser presenter, one per operation, so the operation can cancel it.
    /// The system browser, unless a test replaces it with a spy.
    let makeHostedUIPresenter: @Sendable () -> any HostedUISessionBehavior
    /// The hosted UI's token endpoint session. `makeURLSession`, unless a test scripts the endpoint.
    let makeHostedUIURLSession: @Sendable () -> URLSession
    /// The advanced-security client, which also describes the device to Cognito (the context data, a confirmed
    /// device's name, the sign-up validation data). `CognitoUserPoolASF()` over the system's device, unless a
    /// unit test fixes the device so it never reads `UIDevice` or `UIScreen`.
    let makeAdvancedSecurity: UserPoolEnvironment.CognitoUserPoolASFFactory

    init(
        authConfiguration: AuthConfiguration,
        clients: CognitoServiceClients,
        devices: DeviceRecordIO,
        analytics: LazyUserPoolAnalytics,
        logger: ClientEngineLogger = ClientEngineLogger(),
        services: EngineServices? = nil,
        makeHostedUIPresenter: @escaping @Sendable () -> any HostedUISessionBehavior = { HostedUIASWebAuthenticationSession() },
        makeHostedUIURLSession: @escaping @Sendable () -> URLSession = EngineResources.makeURLSession,
        makeAdvancedSecurity: @escaping UserPoolEnvironment.CognitoUserPoolASFFactory = { CognitoUserPoolASF() }
    ) {
        self.authConfiguration = authConfiguration
        self.clients = clients
        self.devices = devices
        self.analytics = analytics
        self.logger = logger
        self.services = services ?? EngineServices(clients: clients)
        self.makeHostedUIPresenter = makeHostedUIPresenter
        self.makeHostedUIURLSession = makeHostedUIURLSession
        self.makeAdvancedSecurity = makeAdvancedSecurity
    }

    /// The resources of a session engine: device records over the real keychain, in the session's access
    /// group; analytics for the configuration's Pinpoint app, which is always `nil` today, so it never reads.
    init(context: SessionEngineContext) {
        let authConfiguration = AuthConfiguration(client: context.configuration)
        self.init(
            authConfiguration: authConfiguration,
            clients: context.clients,
            devices: DeviceRecordIO(store: DeviceRecordStore(namespace: context.namespace)),
            analytics: LazyUserPoolAnalytics(pinpointAppId: authConfiguration.getUserPoolConfiguration()?.pinpointAppId)
        )
    }

    // MARK: One operation's machinery

    /// Builds one operation (a fresh machine per operation, seeded from the payload it was handed).
    ///
    /// 1. Decodes `seed` with the plugin store's coder into the operation's `CredentialSlot`; `nil` means no
    ///    credentials.
    /// 2. Builds a `ClientCredentialStore` over the slot and the device records.
    /// 3. Builds the engine's environments through `AuthEnvironmentFactory`, with the inert legacy keychain
    ///    (the client never migrates AWSMobileClient data) and this engine's single analytics instance.
    /// 4. Builds the two state machines from them, exactly as the plugin does (`+Configure.swift`).
    ///
    /// No event is sent: configuring the machines, and running the operation, is the network adapter's.
    /// Building does no I/O.
    ///
    /// - Parameters:
    ///   - presenter: the hosted UI's browser for this operation, which the caller keeps to cancel it; a new
    ///     one from `makeHostedUIPresenter` when `nil`.
    ///   - identityPolicy: what a hosted-UI sign-in in this operation checks about the tokens it gets back.
    ///     `.none` checks nothing, as the plugin.
    /// - Throws: the decoding error, if `seed` is not an `AmplifyCredentials` payload.
    ///
    /// - Parameter resuming: The state the auth machine starts in, for a sign-in resumed from its challenge record,
    ///   which skips configuring: `EngineOperation.primeCredentialStore()` then does the part of it the
    ///   machine needs. `nil` starts where every operation does, not configured.
    func makeOperation(
        seed: Data?,
        presenter: (any HostedUISessionBehavior)? = nil,
        identityPolicy: HostedUIIdentityPolicy = .none,
        resuming: AuthState? = nil
    ) throws -> EngineOperation {
        let slot = try CredentialSlot(payload: seed)
        let credentialStore = ClientCredentialStore(slot: slot, devices: devices)
        let userPool = authConfiguration.getUserPoolConfiguration()
        let tap = IssuedTokenTap(clientId: userPool?.clientId, clientSecret: userPool?.clientSecret)
        let factory = makeEnvironmentFactory(
            credentialStore: credentialStore,
            tap: tap,
            presenter: presenter ?? makeHostedUIPresenter(),
            identityPolicy: identityPolicy
        )

        let credentialMachine = StateMachine(
            resolver: CredentialStoreState.Resolver().eraseToAnyResolver(),
            environment: factory.makeCredentialEnvironment()
        )
        let credentialsClient = CredentialStoreOperationClient(credentialStoreStateMachine: credentialMachine)
        let authEnvironment = factory.makeAuthEnvironment(credentialsClient: credentialsClient)
        let authMachine = StateMachine(
            resolver: AuthState.Resolver(logger: authEnvironment.logger).eraseToAnyResolver(),
            environment: authEnvironment,
            initialState: resuming
        )
        return EngineOperation(
            slot: slot,
            credentialStore: credentialStore,
            tokenTap: tap,
            authMachine: authMachine,
            credentialMachine: credentialMachine,
            webAuthnSignIn: authEnvironment.webAuthnSignInCeremony,
            credentialsClient: credentialsClient
        )
    }

    /// The engine's environment factory, with the client's inputs. Every closure is
    /// only stored here; the environments call them.
    ///
    /// - Parameter tap: when given, the operation's user pool shows every sign-in answer to it first, so a
    ///   cancel can revoke tokens a call in flight returns.
    ///   - presenter: the one browser presenter every hosted-UI step of the operation uses.
    ///   - identityPolicy: the hosted-UI sign-in's identity checks.
    func makeEnvironmentFactory(
        credentialStore: ClientCredentialStore,
        tap: IssuedTokenTap? = nil,
        presenter: (any HostedUISessionBehavior)? = nil,
        identityPolicy: HostedUIIdentityPolicy = .none
    ) -> AuthEnvironmentFactory {
        let services = services
        let analytics = analytics
        let presenter = presenter ?? makeHostedUIPresenter()
        return AuthEnvironmentFactory(
            authConfiguration: authConfiguration,
            makeUserPool: {
                let userPool = try Self.required(services.userPool, "user pool")
                return tap.map { TappedUserPool(base: userPool, tap: $0) } ?? userPool
            },
            makeIdentityClient: { try Self.required(services.identity, "identity pool") },
            credentialStoreFactory: { credentialStore },
            legacyKeychainStoreFactory: InertLegacyKeychain.factory,
            logger: logger,
            userPoolAnalytics: { analytics },
            makeURLSession: makeHostedUIURLSession,
            makeHostedUISession: { presenter },
            hostedUIIdentityPolicy: identityPolicy,
            hostedUIIssuedRefreshToken: Self.issuedRefreshTokenObserver(tap: tap, userPool: services.userPool),
            makeAdvancedSecurity: makeAdvancedSecurity
        )
    }

    /// Shows the hosted UI's code exchange to the same tap as the user pool's answers, so a refresh token the
    /// exchange returns after the operation was cancelled is revoked, once, by the tap.
    static func issuedRefreshTokenObserver(
        tap: IssuedTokenTap?,
        userPool: (any CognitoUserPoolBehavior)?
    ) -> HostedUIEnvironment.IssuedRefreshTokenObserver? {
        guard let tap, let userPool else {
            return nil
        }
        return { refreshToken in tap.observe(refreshToken, revokingWith: userPool) }
    }

    /// The plugin's `makeURLSession()` with no network preferences: the default configuration without a
    /// URL cache. Used only by the hosted UI's token exchange.
    @Sendable
    static func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    /// An SDK client the engine asked for. The engine only asks for a pool's client when that pool is
    /// configured, and the session's clients exist for exactly the configured pools, so the error is
    /// unreachable; it replaces a force unwrap.
    static func required<Client>(_ client: Client?, _ pool: String) throws -> Client {
        guard let client else {
            throw EngineAuthError.configuration(
                "The \(pool) is not configured for this session.",
                "Configure the \(pool) in AuthClientConfiguration."
            )
        }
        return client
    }
}

/// The Cognito services an engine calls: the session's SDK clients in the app, scripted doubles in tests.
/// `nil` for a pool the configuration does not have.
struct EngineServices: Sendable {
    let userPool: (any CognitoUserPoolBehavior)?
    let identity: (any CognitoIdentityBehavior & Sendable)?

    init(userPool: (any CognitoUserPoolBehavior)?, identity: (any CognitoIdentityBehavior & Sendable)?) {
        self.userPool = userPool
        self.identity = identity
    }

    /// The session's own SDK clients, the instances the escape hatches return.
    init(clients: CognitoServiceClients) {
        self.init(userPool: clients.userPool, identity: clients.identity)
    }
}

/// One operation's machinery. Built by `EngineResources.makeOperation(seed:)` and discarded
/// afterwards, except inside a pending sign-in attempt.
struct EngineOperation: Sendable {
    /// The session payload, in memory: seeded, then read back at the end.
    let slot: CredentialSlot
    let credentialStore: ClientCredentialStore
    /// The refresh tokens this operation's sign-in was issued; a cancel revokes them.
    let tokenTap: IssuedTokenTap
    let authMachine: StateMachine<AuthState, AuthEnvironment>
    let credentialMachine: StateMachine<CredentialStoreState, CredentialEnvironment>
    /// How this operation's WebAuthn sign-in asserts: the auth environment's slot, which the live engine
    /// fills before each sign-in step with the step's window and sheet-lease runner.
    let webAuthnSignIn: WebAuthnSignInCeremonySlot
    /// The credential machine's client, the one the auth environment uses.
    let credentialsClient: CredentialStoreOperationClient

    /// What configuring does to the credential machine, for an operation that starts past configuring (a resumed
    /// sign-in): one load of the credentials through the auth environment's own client, as
    /// `InitializeAuthConfiguration` does, so the machine leaves `.notConfigured`. A machine still there ignores a
    /// store, and a completed sign-in's store would wait for good. The load's answer is not needed: the slot is
    /// the payload (an empty slot answers "not found").
    func primeCredentialStore() async {
        _ = try? await credentialsClient.fetchData(type: .amplifyCredentials)
    }
}

/// The engine's logger in the client: `AmplifyFoundation` logging under the category `AmplifyCognitoClient`.
/// A scope the engine asks for is logged under `AmplifyCognitoClient.<scope>`, the scope
/// named as the engine's default router names it. **No session ID** appears in either: an app-chosen ID can
/// be an email address.
struct ClientEngineLogger: EngineScopedLogger {

    static let category = "AmplifyCognitoClient"

    let name: String

    init(name: String = ClientEngineLogger.category) {
        self.name = name
    }

    func scoped(_ scope: EngineLogScope) -> EngineLogger {
        ClientEngineLogger(name: "\(Self.category).\(FoundationEngineLogRouter.name(for: scope))")
    }

    private var logger: any AmplifyFoundation.Logger {
        AmplifyLogging.logger(for: name)
    }

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.error(message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.warn(message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.info(message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.debug(message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.verbose(message(), error())
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        logger.log(logLevel, message(), error())
    }
}
