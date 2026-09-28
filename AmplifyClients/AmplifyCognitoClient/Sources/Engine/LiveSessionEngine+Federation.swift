//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import InternalAWSCognitoAuth

/// Federation to the identity pool, ported from the plugin's `AWSAuthFederateToIdentityPoolTask`.
///
/// One fresh operation, as every session operation: seeded with the session's guest or federated payload (the
/// states the core lets federate), sent `.startFederationToIdentityPool`, and read back once the machine has
/// federated. The engine's `InitializeFederationToIdentityPool` then calls `GetId` with the provider's login,
/// or, with a developer-provided identity ID, goes straight to `GetCredentialsForIdentity` with it. Nothing is
/// stored here: the core commits the payload. Refreshing a federated payload is `refresh(_:force:)`, which sends
/// the same event with the stored token and identity, as the plugin's `refreshIfRequired` does; a stored login
/// the identity pool no longer accepts is `refreshTokenInvalid` (`federatedRefreshResult(for:in:)`).
extension LiveSessionEngine {

    /// - Returns: the `identityPoolWithFederation` payload the machine established.
    /// - Throws: `configuration` without an identity pool; `SessionEngineError.service` with the mapped
    ///   failure when the identity pool rejects the token (a bad token is `notAuthorized`, as in the plugin);
    ///   `unknown` if the machine established anything but a federated payload.
    nonisolated func federateToIdentityPool(_ request: EngineFederationRequest, current: Data?) async throws -> Data {
        try requireIdentityPool()
        let seed = try current.flatMap(Self.federationSeed)
        let operation = try resources.makeOperation(seed: seed)
        try await operation.configure(resources.authConfiguration)
        let token = FederatedToken(token: request.token, provider: EngineAuthProvider(request.provider))
        await operation.send(AuthorizationEvent(eventType: .startFederationToIdentityPool(
            token,
            request.developerProvidedIdentityId
        )))
        return try await operation.firstState { state in
            guard case .configured(let authentication, let authorization, _) = state else {
                return nil
            }
            switch (authentication, authorization) {
            case (.federatedToIdentityPool, .sessionEstablished(let credentials)):
                guard case .identityPoolWithFederation = credentials else {
                    // The plugin's `getFederatedResult` string.
                    throw AuthClientError.unknown(
                        "Unable to parse credentials to expected output",
                        "This is not expected. Retry the federation."
                    )
                }
                return try operation.payload(establishing: credentials)
            case (.error, .error(let error)):
                throw SessionEngineError.service(AuthClientError(engine: error.engineError))
            default:
                return nil
            }
        }
    }

    /// The classification of a failed refresh of a federated payload: `refreshResult(for:in:)`'s, except that
    /// the identity pool rejecting the stored login (`NotAuthorizedException`: the provider token expired or
    /// was revoked) is `refreshTokenInvalid`, so the core marks the session expired (`.sessionExpired`) and the
    /// app federates again, as a user pool session whose refresh token died signs in again. The plugin instead
    /// reports a session with no guest access and moves its machine to an error state.
    static func federatedRefreshResult(for error: AuthorizationError, in operation: EngineOperation) throws -> Data {
        if rejectsTheLogin(error) {
            throw SessionEngineError.refreshTokenInvalid
        }
        return try refreshResult(for: error, in: operation)
    }

    /// Whether the identity pool refused the federated login: `GetCredentialsForIdentity` (or `GetId`, when the
    /// engine retries a stale identity) answered `NotAuthorizedException`.
    static func rejectsTheLogin(_ error: AuthorizationError) -> Bool {
        switch error {
        case .sessionExpired, .sessionError(.notAuthorized, _):
            return true
        case .sessionError(.service(let serviceError), _), .service(error: let serviceError):
            return serviceError is AWSCognitoIdentity.NotAuthorizedException
        case .configuration, .invalidState, .sessionError:
            return false
        }
    }

    /// `current` as a federation's seed: a guest or federated payload, so the machine starts from the state
    /// the plugin's would be in (`signedOut` or `federatedToIdentityPool`, with the session established).
    /// Anything else starts from no credentials.
    static func federationSeed(_ current: Data) throws -> Data? {
        switch try credentials(in: current) {
        case .identityPoolOnly, .identityPoolWithFederation:
            return current
        case .userPoolOnly, .userPoolAndIdentityPool, .noCredentials:
            return nil
        }
    }
}

extension EngineAuthProvider {

    /// The engine's provider for the client's, case for case. The identity pool login key is the engine's
    /// (`identityPoolProviderName`): `graph.facebook.com`, `accounts.google.com`, or the name as given.
    init(_ provider: AuthClientProvider) {
        switch provider {
        case .amazon: self = .amazon
        case .apple: self = .apple
        case .facebook: self = .facebook
        case .google: self = .google
        case .twitter: self = .twitter
        case .oidc(let name): self = .oidc(name)
        case .saml(let name): self = .saml(name)
        case .custom(let name): self = .custom(name)
        }
    }
}
