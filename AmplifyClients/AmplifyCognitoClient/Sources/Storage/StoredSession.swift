//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// One row of an account picker: a session saved on this device.
///
/// Built from the saved record's listing metadata alone, with no network call and without decoding
/// credentials. A row says a session was saved and who it belonged to; it cannot say the session still
/// works, because refresh-token expiry is only discovered by using it.
@_spi(AmplifyExperimental)
public struct StoredSession: Sendable, Equatable {

    /// The ID to construct the Auth Client the user picked.
    public let sessionId: SessionID

    /// The app-supplied display name, the only name a user recognises. `nil` until the app sets one with
    /// `setSessionLabel(_:)`. It survives sign-out, and is cleared when a different user signs in to the
    /// session.
    public let label: String?

    /// A fallback row title. `nil` for a guest row, and for a record that never had a user.
    public let username: String?

    /// What the saved record is, for rendering or filtering rows.
    public let kind: SessionKind

    /// Public so an app can build one for a test double; the client builds its own.
    public init(sessionId: SessionID, label: String?, username: String?, kind: SessionKind) {
        self.sessionId = sessionId
        self.label = label
        self.username = username
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
    /// fetched on first use (see "Changing the configuration" on `AmplifyCognitoClient`).
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
