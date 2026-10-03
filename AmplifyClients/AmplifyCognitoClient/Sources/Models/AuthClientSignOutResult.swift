//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// What a sign-out achieved, in the plugin's shape (`AWSCognitoSignOutResult`).
///
/// **A sign-out never throws.** Every outcome is returned: `.complete` and `.partial` when the session is
/// signed out on this device, `.failed` when it is not. Check `signedOutLocally`, or switch over the result.
///
/// The client's own type: the client does not depend on Amplify core, so it does not use the plugin's
/// `AuthSignOutResult`. Unlike the plugin's, `.partial` carries errors only, never tokens.
///
/// May gain cases, or `.partial` gain associated values, in a minor release while the client is
/// experimental: include `@unknown default` when you switch over it. A new associated value on `.partial`
/// is a source break for code that matches all of them.
@_spi(AmplifyExperimental)
public enum AuthClientSignOutResult: Sendable, Equatable {

    /// The session's tokens were revoked and its credentials cleared from this device, or it held none.
    case complete

    /// The credentials were cleared from this device, so the session is signed out here, but part of the
    /// work failed. Each value is `nil` when its part succeeded or was not needed.
    ///
    /// - revokeTokenError: Why revoking the session's tokens failed. The refresh token stays valid
    ///   server-side until it expires. After a failed global sign-out the tokens are not revoked, and this
    ///   holds a placeholder `.service` error with an empty description, as the plugin's does.
    /// - globalSignOutError: Why the global sign-out failed, when one was asked for. The user's other
    ///   sessions, on this device or elsewhere, stay signed in.
    /// - hostedUIError: Why the hosted UI's sign-out did not run. Needed only after a hosted-UI sign-in that
    ///   shared the browser's cookies (`WebUIOptions.prefersEphemeralSession` off). **The hosted UI's cookie
    ///   survives in the browser**, so the next hosted-UI sign-in may silently return the same account: sign
    ///   in next time with `prompt: [.login]`, or with `prefersEphemeralSession: true`. `validation` for a
    ///   sign-out given no window (`signOut(options:)`); `userCancelled` when the user closed the page of a
    ///   session whose refresh token was already dead, which signs out anyway. A page that was asked for and
    ///   could not be shown or completed is `.failed` instead.
    /// - storageError: The client's own: the session was signed out, but `purgeStoredSession` could not
    ///   remove its saved row. A `storageUnavailable` error; purge the session to remove the row.
    case partial(
        revokeTokenError: AuthClientError?,
        globalSignOutError: AuthClientError?,
        hostedUIError: AuthClientError?,
        storageError: AuthClientError?
    )

    /// The sign-out did not happen, and the session is still signed in on this device:
    /// - `storageUnavailable` when storage could not be read or written, or the saved record kept changing
    ///   (`.interrupted`);
    /// - `invalidState` when another sign-in replaced the session while it was signing out; that user is
    ///   left signed in;
    /// - `userCancelled` when the user closed the hosted UI's sign-out page;
    /// - for `signOut(presentationAnchor:options:)` after a sign-in that shared the browser's cookies, when the
    ///   page could not be shown or completed, as the plugin does: `configuration` when the configuration has
    ///   no hosted UI, or no sign-out redirect URI, to sign it out of; `browserBusy` when another sheet holds
    ///   the browser; `validation` when the window has closed; or the browser's own failure;
    /// - `unknown`, with a `CancellationError` as its underlying error, when the calling task was cancelled
    ///   before anything was revoked;
    /// - `sessionConfigurationMismatch` from `signOutStoredSession` when a client for the session is live with
    ///   a different configuration.
    case failed(AuthClientError)

    /// Whether the session is signed out on this device: `false` only for `.failed`.
    public var signedOutLocally: Bool {
        if case .failed = self {
            return false
        }
        return true
    }

    /// Errors compare as `AuthSessionState.failed` does: same case, structured payload, description and
    /// suggestion. The underlying error is not compared.
    public static func == (lhs: AuthClientSignOutResult, rhs: AuthClientSignOutResult) -> Bool {
        switch (lhs, rhs) {
        case (.complete, .complete):
            return true
        case (
            .partial(let lhsRevoke, let lhsGlobal, let lhsHostedUI, let lhsStorage),
            .partial(let rhsRevoke, let rhsGlobal, let rhsHostedUI, let rhsStorage)
        ):
            return equivalent(lhsRevoke, rhsRevoke)
                && equivalent(lhsGlobal, rhsGlobal)
                && equivalent(lhsHostedUI, rhsHostedUI)
                && equivalent(lhsStorage, rhsStorage)
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.isEquivalent(to: rhsError)
        default:
            return false
        }
    }

    static func equivalent(_ lhs: AuthClientError?, _ rhs: AuthClientError?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let left?, let right?):
            return left.isEquivalent(to: right)
        default:
            return false
        }
    }
}
