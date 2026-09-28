//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The four events the Hub sends today for the Auth plugin's session: signed in, signed out, session
/// expired and user deleted.
///
/// Delivered per session: the session an event is about is the stream it arrives on, so the event
/// carries no session identity of its own.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthEvent: Sendable, Equatable {

    /// A user signed in to the session, by any means. Federating to the identity pool sends none.
    case signedIn

    /// The session's credentials were removed: by a sign-out, a purge, or a cleared federation. Not sent when
    /// there were none to remove.
    case signedOut

    /// The session's refresh token (or, for a federated session, its provider token) was found dead: the
    /// session needs a fresh sign-in, and its credentials throw `sessionExpired` until then.
    case sessionExpired

    /// The session's user was deleted from the user pool, and the session signed out.
    case userDeleted
}
