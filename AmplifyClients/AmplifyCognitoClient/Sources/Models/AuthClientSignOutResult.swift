//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// What a sign-out achieved.
///
/// **Outcomes are returned; failures are thrown.** A sign-out that could not do its job — storage could
/// not be read or written, or another writer kept changing the record — throws `AuthClientError`, and the
/// session may still be signed in. Every returned case is a sign-out that ran to an answer.
///
/// The client's own type: the client does not depend on Amplify core, so it does not use the plugin's
/// `AuthSignOutResult`. The plugin bridge maps between them.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientSignOutResult: Sendable, Equatable {

    /// The session's tokens were revoked and its credentials cleared from this device, or it held none.
    case complete

    /// The credentials were cleared from this device, so the session is signed out here, but part of the
    /// work failed: server-side, or the hosted UI's sign-out in the browser. See `AuthClientPartialSignOut`
    /// for which part.
    case partial(AuthClientPartialSignOut)

    /// The session now holds a different user than the one this sign-out set out to remove — another
    /// process signed them in meanwhile — and they were left signed in.
    case superseded
}

/// The parts of a sign-out that failed, when the local sign-out succeeded: server-side, or the hosted UI's
/// sign-out in the browser.
///
/// A struct rather than associated values on `AuthClientSignOutResult.partial`, so parts can be added
/// without breaking callers.
@_spi(AmplifyExperimental)
public struct AuthClientPartialSignOut: Sendable, Equatable {

    /// Why revoking the session's tokens failed, or `nil` if revoking succeeded. When it failed, the
    /// refresh token stays valid server-side until it expires. The first failure, if there were several.
    public let revokeError: AuthClientError?

    /// Why the global sign-out failed, or `nil` if it succeeded or was not asked for. When it failed, the
    /// user's other sessions — on this device or elsewhere — stay signed in. The first failure, if there
    /// were several.
    public let globalSignOutError: AuthClientError?

    /// Why the hosted UI's sign-out did not run, or `nil` if it ran or was not needed. Needed only after a
    /// hosted-UI sign-in that shared the browser's cookies (`WebUIOptions.prefersEphemeralSession` off).
    ///
    /// Unlike the two server-side failures above, this one is on the device: the tokens were revoked and the
    /// session is signed out here, but **the hosted UI's cookie survives in the browser**, so the next
    /// hosted-UI sign-in may silently return the same account. Sign in next time with `prompt: [.login]`, or
    /// with `prefersEphemeralSession: true`. `browserBusy` when another sheet held the browser, `validation`
    /// for a sign-out given no window, `configuration` when the configuration has no hosted UI, or the
    /// browser's own failure.
    public let hostedUIError: AuthClientError?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(
        revokeError: AuthClientError? = nil,
        globalSignOutError: AuthClientError? = nil,
        hostedUIError: AuthClientError? = nil
    ) {
        self.revokeError = revokeError
        self.globalSignOutError = globalSignOutError
        self.hostedUIError = hostedUIError
    }

    /// Errors compare as `AuthSessionState.failed` does: same case, structured payload, description and
    /// suggestion. The underlying error is not compared.
    public static func == (lhs: AuthClientPartialSignOut, rhs: AuthClientPartialSignOut) -> Bool {
        equivalent(lhs.revokeError, rhs.revokeError)
            && equivalent(lhs.globalSignOutError, rhs.globalSignOutError)
            && equivalent(lhs.hostedUIError, rhs.hostedUIError)
    }

    private static func equivalent(_ lhs: AuthClientError?, _ rhs: AuthClientError?) -> Bool {
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
