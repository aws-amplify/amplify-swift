//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Federation to the identity pool, with the plugin's semantics, for this session only.
///
/// A federated session reports `AuthSessionState.federated(identityId:)`: it holds an identity pool
/// identity and its AWS credentials, and no user pool user. Its credentials provider vends those
/// credentials, refreshed with the stored provider token when they expire; its access-token provider has
/// none to give. `signIn` refuses it (`invalidState`): clear the federation, or sign it out, first. When the
/// identity pool no longer accepts the stored provider token, the session sends `.sessionExpired` and its
/// credentials throw `sessionExpired` until it federates again.
///
/// **Events.** Federating sends no event, as no user signs in, including a federation that replaces another
/// identity or a guest's: the identity changes silently on the event stream. Listen to
/// `listenToSessionStateChanges()` for identity changes (`.federated(identityId:)`). Clearing sends
/// `.signedOut`.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Exchanges a token from an identity provider for this session's identity pool credentials.
    ///
    /// - Parameters:
    ///   - withProviderToken: The provider's token.
    ///   - provider: The provider that issued it.
    ///   - options: A developer-provided identity ID, if the backend already has one.
    /// - Returns: The federated identity's credentials and ID.
    /// - Throws: `AuthClientError.configuration` without an identity pool; `.invalidState` if this session is
    ///   signed in to the user pool or waiting on a challenge, before any request (sign out first); if a
    ///   user or another federated identity was stored for it meanwhile; or if a sign-out, purge, deletion or
    ///   clear of this session ended it while the call was in progress ("The federation was cancelled…",
    ///   nothing stored); `.notAuthorized` when the identity pool rejects the token; `.storageUnavailable`;
    ///   `.service` as Cognito answers otherwise.
    func federateToIdentityPool(
        withProviderToken: String,
        for provider: AuthClientProvider,
        options: AuthClientFederateToIdentityPoolOptions = AuthClientFederateToIdentityPoolOptions()
    ) async throws -> AuthClientFederateToIdentityPoolResult {
        let request = EngineFederationRequest(
            token: withProviderToken,
            provider: provider,
            developerProvidedIdentityId: options.developerProvidedIdentityId
        )
        let core = core
        return try await core.federateToIdentityPool(request)
    }

    /// Ends this session's federation, clearing its credentials. The session's row is kept, signed out, with
    /// its label, as after `signOut()`.
    ///
    /// - Throws: `AuthClientError.invalidState` if this session is not federated, or if what is stored is no
    ///   longer the identity it found (a user, or another federation, stored meanwhile: nothing is cleared);
    ///   `.storageUnavailable` if storage could not be read or written.
    func clearFederationToIdentityPool() async throws {
        let core = core
        try await core.clearFederationToIdentityPool()
    }
}
