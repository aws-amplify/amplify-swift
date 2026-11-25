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
/// `AuthSignOutResult`. `.partial`'s parts are wrappers, as the plugin's are (`revokeTokenError?.error`), but
/// unlike the plugin's they carry errors only, never tokens.
///
/// May gain cases, or `.partial` gain associated values, in a minor release while the client is
/// experimental: include `@unknown default` when you switch over it. A new associated value on `.partial`
/// is a source break for code that matches all of them.
@_spi(AmplifyExperimental)
public enum AmplifyCognitoClientSignOutResult: Sendable, Equatable {

    /// The session's tokens were revoked and its credentials cleared from this device, or it held none.
    case complete

    /// The credentials were cleared from this device, so the session is signed out here, but part of the
    /// work failed. Each value is `nil` when its part succeeded or was not needed.
    ///
    /// - revokeTokenError: Why revoking the session's tokens failed: see `AmplifyCognitoClientRevokeTokenError`.
    /// - globalSignOutError: Why the global sign-out failed, when one was asked for: see
    ///   `AmplifyCognitoClientGlobalSignOutError`.
    /// - hostedUIError: Why the hosted UI's sign-out did not run: see `AmplifyCognitoClientHostedUIError`.
    /// - storageError: The client's own: the session was signed out, but `purgeStoredSession` could not
    ///   remove its saved row. A `storageUnavailable` error; purge the session to remove the row.
    case partial(
        revokeTokenError: AmplifyCognitoClientRevokeTokenError?,
        globalSignOutError: AmplifyCognitoClientGlobalSignOutError?,
        hostedUIError: AmplifyCognitoClientHostedUIError?,
        storageError: AmplifyCognitoClientError?
    )

    /// The sign-out did not happen, and the session is still signed in on this device:
    /// - `storageUnavailable` when storage could not be read or written, or the saved record kept changing
    ///   (`.interrupted`);
    /// - `invalidState` when another sign-in replaced the session while it was signing out; that user is
    ///   left signed in;
    /// - `userCancelled` when the user closed the hosted UI's sign-out page;
    /// - for `signOutWithWebUI(presentationAnchor:options:)` after a sign-in that shared the browser's cookies, when the
    ///   page could not be shown or completed, as the plugin does: `configuration` when the configuration has
    ///   no hosted UI, or no sign-out redirect URI, to sign it out of; `browserBusy` when another sheet holds
    ///   the browser; `validation` when the window has closed; or the browser's own failure;
    /// - `unknown`, with a `CancellationError` as its underlying error, when the calling task was cancelled
    ///   before anything was revoked;
    /// - `sessionConfigurationMismatch` from `signOutStoredSession` when a client for the session is live with
    ///   a different configuration.
    case failed(AmplifyCognitoClientError)

    /// Whether the session is signed out on this device: `false` only for `.failed`.
    public var signedOutLocally: Bool {
        if case .failed = self {
            return false
        }
        return true
    }

    /// Errors compare as `AuthSessionState.failed` does: same case, structured payload, description and
    /// suggestion. The underlying error is not compared.
    public static func == (lhs: AmplifyCognitoClientSignOutResult, rhs: AmplifyCognitoClientSignOutResult) -> Bool {
        switch (lhs, rhs) {
        case (.complete, .complete):
            return true
        case (
            .partial(let lhsRevoke, let lhsGlobal, let lhsHostedUI, let lhsStorage),
            .partial(let rhsRevoke, let rhsGlobal, let rhsHostedUI, let rhsStorage)
        ):
            return lhsRevoke == rhsRevoke
                && lhsGlobal == rhsGlobal
                && lhsHostedUI == rhsHostedUI
                && equivalent(lhsStorage, rhsStorage)
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.isEquivalent(to: rhsError)
        default:
            return false
        }
    }

    static func equivalent(_ lhs: AmplifyCognitoClientError?, _ rhs: AmplifyCognitoClientError?) -> Bool {
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

/// Why revoking the session's tokens failed, in a `.partial` sign-out. The plugin's
/// `AWSCognitoRevokeTokenError`, without its `refreshToken`.
///
/// The refresh token stays valid server-side until it expires, unless a global sign-out succeeded
/// (`globalSignOutError` is `nil`), which already invalidated it. After a failed global sign-out the tokens are
/// not revoked, and `error` is a placeholder `.service` error with an empty description, as the plugin's is.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientRevokeTokenError: Sendable, Equatable {

    /// The revoke's failure.
    public let error: AmplifyCognitoClientError

    /// Public so an app can build one for a test double; the client builds its own.
    public init(error: AmplifyCognitoClientError) {
        self.error = error
    }

    /// Equal when the errors are the same case with the same payload, description and recovery suggestion, as
    /// `AmplifyCognitoClientSignOutResult` compares errors. The underlying error is not compared.
    public static func == (lhs: AmplifyCognitoClientRevokeTokenError, rhs: AmplifyCognitoClientRevokeTokenError) -> Bool {
        lhs.error.isEquivalent(to: rhs.error)
    }
}

/// Why the global sign-out failed, in a `.partial` sign-out that asked for one. The plugin's
/// `AWSCognitoGlobalSignOutError`, without its `accessToken`.
///
/// The user's other sessions, on this device or elsewhere, stay signed in. Neither this failure nor the
/// revoke's is retried, and signing out again does not retry it: the session is signed out on this device, so
/// a second sign-out finds nothing to sign out and is `.complete`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientGlobalSignOutError: Sendable, Equatable {

    /// The global sign-out's failure.
    public let error: AmplifyCognitoClientError

    /// Public so an app can build one for a test double; the client builds its own.
    public init(error: AmplifyCognitoClientError) {
        self.error = error
    }

    /// Equal when the errors are the same case with the same payload, description and recovery suggestion, as
    /// `AmplifyCognitoClientSignOutResult` compares errors. The underlying error is not compared.
    public static func == (lhs: AmplifyCognitoClientGlobalSignOutError, rhs: AmplifyCognitoClientGlobalSignOutError) -> Bool {
        lhs.error.isEquivalent(to: rhs.error)
    }
}

/// Why the hosted UI's sign-out did not run, in a `.partial` sign-out. The plugin's `AWSCognitoHostedUIError`.
///
/// Needed only after a hosted-UI sign-in that shared the browser's cookies
/// (`WebUIOptions.prefersEphemeralSession` off). **The hosted UI's cookie survives in the browser**, so the next
/// hosted-UI sign-in may silently return the same account: sign in next time with `prompt: [.login]`, or with
/// `prefersEphemeralSession: true`. `error` is `validation` for a sign-out given no window
/// (`signOut(options:)`); `userCancelled` when the user closed the page of a session whose refresh token was
/// already dead, which signs out anyway. A page that was asked for and could not be shown or completed is
/// `.failed` instead.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientHostedUIError: Sendable, Equatable {

    /// Why the hosted UI's sign-out did not run.
    public let error: AmplifyCognitoClientError

    /// Public so an app can build one for a test double; the client builds its own.
    public init(error: AmplifyCognitoClientError) {
        self.error = error
    }

    /// Equal when the errors are the same case with the same payload, description and recovery suggestion, as
    /// `AmplifyCognitoClientSignOutResult` compares errors. The underlying error is not compared.
    public static func == (lhs: AmplifyCognitoClientHostedUIError, rhs: AmplifyCognitoClientHostedUIError) -> Bool {
        lhs.error.isEquivalent(to: rhs.error)
    }
}
