//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// One row of an account picker: a session saved on this device.
///
/// Built from the saved record alone, with no network call. A row says a session was saved and who it
/// belonged to; it cannot say the session still works, because refresh-token expiry is only discovered by
/// using it.
@_spi(AmplifyExperimental)
public struct StoredSession: Sendable, Equatable {

    /// The ID to construct the Auth Client the user picked.
    public let sessionId: SessionID

    /// The app-supplied display name, the only name a user recognises. `nil` until the app sets one with
    /// `setSessionLabel(_:)` or the static `setSessionLabel(_:sessionId:configuration:accessGroup:)`, or a sign-in
    /// saves the one its session ID was created with (`SessionID.label`). It survives sign-out. When a different
    /// user signs in to the session through a client it is cleared, or replaced by that ID's label if it has
    /// one. For `.default`, a different user signed in by the Auth plugin, which never
    /// writes the label, only hides it: it is listed again once that user is signed out or the labelled user
    /// signs back in, unless a client wrote the session for the other user meanwhile, which clears it.
    public let label: String?

    /// Who the row belongs to: the signed-in user, or a signed-out row's last user. The same value as
    /// `getCurrentUser()` and `AuthSessionState.signedIn(_:)`, so `userId` matches a row to a live client, or to
    /// another row of the same user. `nil` for a guest or federated row, for a row that never had a user, and for a
    /// row saved before records kept the user's ID, unless it is signed in and its saved credentials still name
    /// the user.
    ///
    /// `user.username` is Cognito's username, not a display name: often a UUID, or `<Provider>_<id>` for a user
    /// of another identity provider. The row's title is `label`.
    public let user: AuthClientUser?

    /// What the saved record is, for rendering or filtering rows.
    public let kind: SessionKind

    /// Public so an app can build one for a test double; the client builds its own.
    public init(sessionId: SessionID, label: String?, user: AuthClientUser?, kind: SessionKind) {
        self.sessionId = sessionId
        self.label = label
        self.user = user
        self.kind = kind
    }
}

/// What a *saved* session is: which pools its credentials are for, and how it signed in. Distinct from the
/// state of a live session right now (`AuthSessionState`).
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum SessionKind: Sendable, Equatable {

    /// A user signed in to the user pool, with no identity pool credentials: user pool tokens only. Also a
    /// session carried forward from a configuration without this identity pool, until its identity is
    /// fetched on first use (see "Changing the configuration" on `AmplifyCognitoClient`). A row's kind follows the
    /// current configuration: after a change that removes the identity pool, `.default`'s copied login is listed as
    /// `.userPoolOnly`, and a copied guest or federated identity as `.signedOut`, as a named session is.
    case userPoolOnly

    /// A user signed in to the user pool, with identity pool credentials for that user.
    case userPoolAndIdentityPool

    /// No user: guest (unauthenticated) identity pool credentials.
    case guest

    /// No user pool user: identity pool credentials from another provider's token
    /// (`federateToIdentityPool(withProviderToken:for:options:)`).
    case federated

    /// Signed out: the row was kept, with its label, after a sign-out or a cleared federation. Listed only with
    /// `storedSessions(configuration:accessGroup:includingSignedOut:)`'s `includingSignedOut: true`. (Stored
    /// as `none`, its name before it was renamed.)
    case signedOut
}
