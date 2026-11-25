//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// One row of an account picker: a session saved on this device.
///
/// Built from what is saved for the session alone, with no network call. A row says a session was saved, who it
/// belonged to and what state it is in; it cannot say the session still works, because refresh-token expiry is
/// only discovered by using it.
@_spi(AmplifyExperimental)
public struct StoredSession: Sendable, Equatable {

    /// The ID to build the client the user picked.
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
    /// the user. On an `.awaitingChallenge` row over a signed-out row, `user` and `label` are the signed-out
    /// user's, not those of whoever is signing in.
    ///
    /// `user.username` is Cognito's username, not a display name: often a UUID, or `<Provider>_<id>` for a user
    /// of another identity provider. The row's title is `label`.
    public let user: AmplifyCognitoClientUser?

    /// What the saved record is, for rendering or filtering rows.
    public let kind: SessionKind

    /// What the session is: the state a client built with `sessionId` reports once it has restored
    /// (`currentSessionState()`), read from what is saved, with no network call.
    ///
    /// - `.signedIn(user)`: signed in to the user pool, with or without AWS credentials. Also for a session whose
    ///   refresh token a refresh already proved dead, as a live client reports it: its calls throw `sessionExpired`.
    /// - `.guest`, `.federated(identityId:)`: identity pool credentials, for nobody or for another provider's user.
    /// - `.signedOut`: a row kept after a sign-out. Listed only with `includingSignedOut: true`.
    /// - `.awaitingChallenge(step)`: a sign-in stopped on a challenge and was saved, over a signed-out or guest row
    ///   or with nothing else saved for the session. To resume it, build a client with `sessionId` and answer
    ///   the step its `currentSessionState()` reports with `confirmSignIn`: the row's may have expired since.
    /// - `.failed`: the saved record is one this version cannot read or use (saved by a newer version, or damaged),
    ///   with the error a client restores to. A readable record that does not itself name its user (one saved
    ///   before records kept the user's ID, or a federated one) is `.failed` too, with its `label` and `kind` as
    ///   saved, when its credentials cannot be read, or name no user or identity; a record that names its user is
    ///   `.signedIn` without its credentials being read. Signing the session out resets a `.failed` row to a
    ///   signed-out row; purging it removes the row.
    ///
    /// Never `.unavailable`: the listing throws when storage cannot be read. The row is a snapshot of what is
    /// saved, so a client live in this process may have moved on since.
    ///
    /// In two cases a restore changes what is saved, and the client then reports another state than the row did:
    /// - After the app went back to an earlier pool configuration (a rollback), a session that was signed out or
    ///   purged under the later configuration is still listed from the copy left under the earlier one, as it was
    ///   saved. Its restore removes that copy, and restores as a session with nothing saved.
    /// - `.default`, before its first restore after a configuration change that copies the Auth plugin's saved
    ///   login to the new configuration: if that login is one this version cannot read, the row is whatever the new
    ///   configuration already holds (often no row). Its restore copies the login and is `.failed`, as the row then
    ///   is.
    public let state: AuthSessionState

    /// Public so an app can build one for a test double; the client builds its own.
    public init(sessionId: SessionID, label: String?, user: AmplifyCognitoClientUser?, kind: SessionKind, state: AuthSessionState) {
        self.sessionId = sessionId
        self.label = label
        self.user = user
        self.kind = kind
        self.state = state
    }
}

/// What a *saved* session is: which pools its credentials are for, and how it signed in. Distinct from the
/// session's state (`AuthSessionState`), which a row reports beside it (`StoredSession.state`).
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum SessionKind: Sendable, Equatable {

    /// A user signed in to the user pool, with no identity pool credentials: user pool tokens only. Also a
    /// session carried forward from a configuration without this identity pool, until its identity is
    /// fetched on first use (see "Changing the configuration" on `AmplifyCognitoClient`). A row's kind follows the
    /// current configuration: after a change that removes the identity pool, `.default`'s copied login is listed as
    /// `.userPoolOnly`, and a copied guest or federated identity as `.signedOut`, as a named session is.
    ///
    /// Also the kind of a row whose saved record this version cannot read (its `state` is `.failed`): a record is
    /// there, and this is the smallest claim about one.
    case userPoolOnly

    /// A user signed in to the user pool, with identity pool credentials for that user.
    case userPoolAndIdentityPool

    /// No user: guest (unauthenticated) identity pool credentials. A guest row with a sign-in waiting on a challenge
    /// keeps this kind, and its `state` is `.awaitingChallenge`.
    case guest

    /// No user pool user: identity pool credentials from another provider's token
    /// (`federateToIdentityPool(withProviderToken:for:options:)`).
    case federated

    /// Signed out: the row was kept, with its label, after a sign-out or a cleared federation. Listed only with
    /// `storedSessions(configuration:accessGroup:includingSignedOut:)`'s `includingSignedOut: true`. (Stored
    /// as `none`, its name before it was renamed.)
    ///
    /// Also the kind of a row with no credentials whose sign-in is waiting on a challenge (its `state` is
    /// `.awaitingChallenge`), with or without a kept row: that one is always listed.
    case signedOut
}
