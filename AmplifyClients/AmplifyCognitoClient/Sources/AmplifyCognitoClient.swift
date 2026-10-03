//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation

/// The family's escape-hatch closure for the underlying user pool SDK client, in the shape every
/// sibling uses (`AmplifyKinesisClientConfigurationProvider`). Applied once, to the SDK client's
/// configuration, when the session's clients are built.
@_spi(AmplifyExperimental)
public typealias AmplifyCognitoClientUserPoolConfigurationProvider = (
    inout CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig
) -> Void

/// A handle onto one Cognito session.
///
/// Construction is synchronous and throwing, like every client in the family, and does no file or
/// keychain I/O: the saved session is restored in the background, and every operation waits for that
/// restore internally, bounded, so a caller never has to sequence around it.
///
/// **Two clients with the same session ID are two handles onto one session.** Constructing a second
/// does not create a second session and does not throw; both share one state, one stream of events and
/// one refresh. A session's resources are released once the last handle to it — and the last provider
/// it vended — goes away. Constructing a client with a session ID that is already live under a different
/// configuration throws `sessionConfigurationMismatch` rather than silently attaching.
///
/// ```swift
/// let work = try AmplifyCognitoClient(options: .init(sessionId: .named("work")))
/// let home = try AmplifyCognitoClient(options: .init(sessionId: .named("home")))
/// let kinesis = try AmplifyKinesisClient(region: "us-east-1", credentialsProvider: work.credentialsProvider)
/// ```
///
/// **Amplify's category plugins do not follow these sessions, and nothing warns you.** Storage, Analytics,
/// API and the other categories never ask this client for credentials. They use whatever session
/// `Amplify.Auth` holds, which is the Auth plugin's own session. Choosing a session ID here, `.default`
/// included, does not change it. With several sessions signed in, a category call does not fail because
/// of them: it runs as the Auth plugin's user, or as its guest, or fails if the Auth plugin has no
/// session at all, whichever session you meant. For example, a Storage path built from the identity ID
/// (`StoragePath.fromIdentityID`, or the `.private` and `.protected` access levels) resolves to the Auth
/// plugin session's identity, not that of the session you had in mind, and the call succeeds there.
/// Analytics sends events with the Auth plugin session's AWS credentials. To make AWS calls as a
/// particular session, pass its `credentialsProvider` to a client in the `AmplifyClients` family, as above.
///
/// ## Saved sessions
///
/// A session's credentials are saved in the keychain under its session ID, scoped to the configuration's
/// pools (the user pool ID, the identity pool ID, or both) and to the keychain access group
/// (`Options.accessGroup`). Constructing a client restores the session saved there, in this launch or a
/// later one. `storedSessions(configuration:accessGroup:includingSignedOut:)` lists the sessions saved under
/// one configuration and access group, for an account picker. Signing out keeps a session's row, with its
/// label, until it is purged.
///
/// ## Changing the configuration
///
/// Because saved sessions are scoped to the pools and the access group, a client with a different
/// configuration reads a different set of them, and `storedSessions` lists only that configuration's. When
/// the pools change, a named session is carried forward the first time it is restored, as the plugin carries its
/// record, from the configuration this app last kept that session under (`.default`, the plugin's own record,
/// follows the plugin's rule instead: see `SessionID.default`):
///
/// - an identity pool only, then a user pool added beside it: the guest or federated identity, as it was;
/// - a user pool only, then an identity pool added: signed in, with the identity fetched on first use;
/// - the identity pool changed beside the same user pool: signed in with the user pool tokens only (the
///   new identity pool issues a new identity on first use);
/// - the identity pool removed beside the same user pool: signed in with the user pool tokens only.
///
/// Any other change, such as a different user pool or a different access group, carries nothing, and
/// neither does a session whose latest saved state is signed out. The old record is kept, not moved, so
/// each configuration keeps its own: switching back finds it as it was, except that signing a carried
/// session out or purging it under the new configuration also deletes the record it was carried from while
/// that record is untouched and provably holds the same user (not a guest's). Remembered-device records are not
/// carried, so a remembered device must be remembered again.
///
/// A session is carried when it is restored. While a client or provider for it is live under the old
/// configuration, constructing it under the new one throws `sessionConfigurationMismatch`: release every
/// handle and provider of the session first.
@_spi(AmplifyExperimental)
public final class AmplifyCognitoClient: Sendable {

    /// Per-client options.
    ///
    /// Not `Sendable`: it carries a non-`Sendable` closure. It is consumed synchronously by `init` and
    /// never stored.
    public struct Options {

        /// The session this client is a handle onto. `.default` is the single-account session, and the
        /// only one that uses `AWSCognitoAuthPlugin`'s saved login: it reads and writes the plugin's own record.
        ///
        /// Running the plugin and this client side by side over `.default` in one app is not supported: each keeps
        /// its tokens in memory. See `SessionID.default`.
        public var sessionId: SessionID

        /// The keychain access group to store the session in, to share it between apps and extensions,
        /// as the plugin does today. Part of which record the session reads, so every handle on a
        /// session must pass the same one, and a different group sees different saved sessions.
        public var accessGroup: String?

        /// Customizes the user pool SDK client's configuration.
        ///
        /// Runs after the client has set the configuration's region, its signing region and its AWS
        /// credential identity resolver, so it can override any of them. That resolver always throws,
        /// because every operation the client calls is unsigned: to call an operation that needs AWS
        /// credentials through `getUserPoolClient()`, set `awsCredentialIdentityResolver` here. The HTTP
        /// engine is wrapped for the `User-Agent` after this closure runs, so a custom engine is wrapped
        /// too. The SDK builds its HTTP engine from `httpClientConfiguration` before this closure runs, so
        /// setting only `httpClientConfiguration` (a connect timeout, say) has no effect unless the closure
        /// also replaces `httpClientEngine`.
        ///
        /// Applied only by the handle that builds the session. A handle joining a live session uses the
        /// session's existing SDK client, so its closure is not applied. One handle passing a closure and
        /// another passing none throws `sessionConfigurationMismatch`; two different closures cannot be
        /// compared, so the first handle's wins.
        public var configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider?

        /// - Parameters:
        ///   - sessionId: The session to be a handle onto; `.default` if not given.
        ///   - accessGroup: The keychain access group to store the session in; the app's default if `nil`.
        ///   - configureUserPoolClient: Customizes the user pool SDK client's configuration.
        public init(
            sessionId: SessionID = .default,
            accessGroup: String? = nil,
            configureUserPoolClient: AmplifyCognitoClientUserPoolConfigurationProvider? = nil
        ) {
            self.sessionId = sessionId
            self.accessGroup = accessGroup
            self.configureUserPoolClient = configureUserPoolClient
        }
    }

    /// The session this handle is bound to.
    public let sessionId: SessionID

    /// The session. Strong: a handle keeps its session alive.
    let core: SessionCore

    /// Builds a handle onto the session `options.sessionId` names.
    ///
    /// Switching configuration under one session ID (release the handles of one, then build one with another)
    /// keeps each configuration's saved record: switching back finds that configuration's session as it was, unless it
    /// was signed out there. See `SessionID`.
    ///
    /// - Throws: `AuthClientError.sessionConfigurationMismatch` if that session is already live in this
    ///   process under a different configuration; `AuthClientError.configuration` if the SDK clients
    ///   could not be configured.
    public convenience init(configuration: AuthClientConfiguration, options: Options = Options()) throws {
        try self.init(configuration: configuration, options: options, dependencies: .live)
    }

    /// Builds a handle from the `auth` section of a Gen2 `amplify_outputs` JSON resource.
    ///
    /// Gen2 `amplify_outputs` only: a Gen1 `amplifyconfiguration.json` is refused. The file is read by
    /// `AuthClientConfiguration.init(from:bundle:)`, never by the client itself.
    ///
    /// - Throws: `AuthClientError.configuration` naming the problem with the resource, or anything
    ///   `init(configuration:options:)` throws.
    public convenience init(
        from resource: String = "amplify_outputs",
        bundle: Bundle = .main,
        options: Options = Options()
    ) throws {
        try self.init(configuration: AuthClientConfiguration(from: resource, bundle: bundle), options: options)
    }

    /// The designated initializer, with every dependency injectable.
    ///
    /// No `await` and no keychain call: the core is found or built under the registry lock, and its
    /// restore is only scheduled.
    init(configuration: AuthClientConfiguration, options: Options, dependencies: SessionCoreDependencies) throws {
        let identity = SessionIdentity(configuration: configuration, options: options)
        let sessionId = options.sessionId
        let configureUserPoolClient = options.configureUserPoolClient
        self.core = try dependencies.registry.session(
            for: sessionId,
            namespace: identity.namespace,
            fingerprint: identity.fingerprint
        ) {
            // Runs under the registry lock: cheap, no `await`, no keychain, no registry call.
            let clients: CognitoServiceClients
            do {
                clients = try dependencies.makeClients(configuration, configureUserPoolClient)
            } catch let error as AuthClientError {
                throw error
            } catch {
                throw AuthClientError.configuration(
                    "The Cognito SDK clients could not be configured.",
                    "Check the region in the configuration, and any changes made by configureUserPoolClient.",
                    error
                )
            }
            let core = try SessionCore(
                sessionId: sessionId,
                configuration: configuration,
                namespace: identity.namespace,
                clients: clients,
                dependencies: dependencies
            )
            dependencies.scheduleRestore(core)
            return core
        }
        self.sessionId = sessionId
    }

    // MARK: Escape hatches

    /// The session's user pool SDK client, or `nil` if no user pool is configured. The same client the
    /// session uses, shared by every handle on it.
    ///
    /// Operations that need AWS (SigV4) credentials, such as the `Admin*` operations, throw
    /// `AuthClientError.configuration` by design, unless `Options.configureUserPoolClient` set an
    /// `awsCredentialIdentityResolver`.
    public func getUserPoolClient() -> CognitoIdentityProviderClient? {
        core.clients.userPool
    }

    /// The session's identity pool SDK client, or `nil` if no identity pool is configured.
    ///
    /// Operations that need AWS (SigV4) credentials, such as `DescribeIdentityPool`, throw
    /// `AuthClientError.configuration` by design. To make them, build your own `CognitoIdentityClient`.
    public func getIdentityClient() -> CognitoIdentityClient? {
        core.clients.identity
    }

    // MARK: Credential providers

    /// This session's AWS credentials, for any client in the family. Bound to this session for life,
    /// and keeps it alive.
    ///
    /// Passing it to a client in the `AmplifyClients` family is how AWS calls are made as this session.
    /// Amplify's category plugins (Storage, Analytics, API and the rest) cannot take it: they always use the
    /// Auth plugin's session in `Amplify.Auth`, whichever session this is.
    public var credentialsProvider: CognitoCredentialsProvider {
        CognitoCredentialsProvider(core: core)
    }

    /// This session's user pool access token. Bound to this session for life, and keeps it alive.
    public var userPoolTokenProvider: CognitoUserPoolTokenProvider {
        CognitoUserPoolTokenProvider(core: core)
    }
}
