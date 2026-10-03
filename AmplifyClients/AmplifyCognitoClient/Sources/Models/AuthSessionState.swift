//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation

/// What this session is, right now. Deliberately close to today's
/// `fetchAuthSession().isSignedIn`, with the cases a Bool cannot express.
///
/// There is no `isSignedIn` convenience, on purpose: it answers wrongly for `.guest` (which holds
/// usable credentials) and for `.unavailable` (a storage failure, not a signed-out user).
///
/// ## Equality
///
/// Every case compares its payload, including `.failed`, even though `AuthClientError` is not
/// `Equatable`. Two `.failed` states are equal when their errors are the same case with the same
/// structured payload (the `StorageUnavailableReason`, the `SessionID`, the validation `field`),
/// the same `errorDescription`, and the same `recoverySuggestion`. The `underlyingError` is not
/// compared, because `any Error` cannot be. That is as close to payload-aware as the error allows,
/// and deliberately not the plugin's payload-blind `AuthError ==`: a session moving from one
/// failure to a different one is a change a state stream must not swallow.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
///
/// **Matching a storage reason.** `StorageUnavailableReason` (and `CredentialsError`, whose `disposition` a
/// consumer reads) is AmplifyFoundation's experimental SPI, like this client. To match `.unavailable(.locked)`
/// or read `disposition`, import it with the SPI: `@_spi(AmplifyExperimental) import AmplifyFoundation`.
@_spi(AmplifyExperimental)
public enum AuthSessionState: Sendable {

    /// Signed in to the user pool, by any means: password, passwordless, hosted UI.
    case signedIn(AuthClientUser)

    /// Federated to the identity pool with a token from another provider
    /// (`federateToIdentityPool(withProviderToken:for:options:)`). There is no user pool user, so no
    /// `AuthClientUser`: the identity pool identity is what the session holds. Its AWS credentials are
    /// usable; operations that need a user pool user throw `notSignedIn`.
    case federated(identityId: String)

    /// No user, and no credentials of any kind. Where a session starts, and
    /// where `signOut()` leaves it. Nothing to sign with.
    case signedOut

    /// No user, but this session holds live unauthenticated identity-pool
    /// credentials, so it can sign AWS requests as nobody in particular.
    /// Reachable ONLY when an identity pool is configured, and only once
    /// something has actually fetched guest credentials - `signedOut` does
    /// not turn into `guest` by itself.
    case guest

    /// A sign-in is part-way through and waiting on the user. The client's own
    /// mirror of the plugin's `AuthSignInStep`, because the client does not
    /// depend on Amplify core.
    ///
    /// It survives the app being closed: the challenge is saved on the device
    /// (never synchronized, never with the password), and a client built later
    /// with the same session ID starts in this state. The app chooses whether to
    /// resume it or start sign-in over.
    case awaitingChallenge(AuthClientSignInStep)

    /// Could not read storage. NOT "signed out" - a retry may succeed.
    case unavailable(StorageUnavailableReason)

    /// Misconfigured or unrecoverable. See "Equality" above for how this case compares.
    case failed(AuthClientError)
}

extension AuthSessionState: Equatable {

    public static func == (lhs: AuthSessionState, rhs: AuthSessionState) -> Bool {
        // Switch on `lhs` with no `default`, so a new case cannot silently compare unequal.
        switch lhs {
        case .signedIn(let user):
            guard case .signedIn(let other) = rhs else { return false }
            return user == other
        case .federated(let identityId):
            guard case .federated(let other) = rhs else { return false }
            return identityId == other
        case .signedOut:
            guard case .signedOut = rhs else { return false }
            return true
        case .guest:
            guard case .guest = rhs else { return false }
            return true
        case .awaitingChallenge(let step):
            guard case .awaitingChallenge(let other) = rhs else { return false }
            return step == other
        case .unavailable(let reason):
            guard case .unavailable(let other) = rhs else { return false }
            return reason == other
        case .failed(let error):
            guard case .failed(let other) = rhs else { return false }
            return error.isEquivalent(to: other)
        }
    }
}

extension AuthClientError {

    /// Which `AuthClientError` case this is, with its structured, comparable payload. Excludes the
    /// strings and the underlying error, which `isEquivalent(to:)` handles separately.
    enum Kind: Equatable {
        case configuration
        case storageUnavailable(StorageUnavailableReason)
        case sessionExpired
        case notSignedIn
        case invalidSessionID
        case challengeExpired
        case browserBusy(holder: SessionID)
        case sessionConfigurationMismatch(SessionID)
        case validation(field: String)
        case service(AuthClientServiceErrorCode?)
        case notAuthorized
        case invalidState
        case userCancelled
        case webAuthnCeremonyFailed(AuthClientWebAuthnCeremonyFailure)
        case unexpectedIdentity(expected: String?, returned: AuthClientUser)
        case unknown
    }

    /// Exhaustive on purpose: a new error case does not compile until it is given a kind.
    var kind: Kind {
        switch self {
        case .configuration: return .configuration
        case .storageUnavailable(let reason, _, _, _): return .storageUnavailable(reason)
        case .sessionExpired: return .sessionExpired
        case .notSignedIn: return .notSignedIn
        case .invalidSessionID: return .invalidSessionID
        case .challengeExpired: return .challengeExpired
        case .browserBusy(let holder, _, _, _): return .browserBusy(holder: holder)
        case .sessionConfigurationMismatch(let id, _, _, _): return .sessionConfigurationMismatch(id)
        case .validation(let field, _, _, _): return .validation(field: field)
        case .service(let code, _, _, _): return .service(code)
        case .notAuthorized: return .notAuthorized
        case .invalidState: return .invalidState
        case .userCancelled: return .userCancelled
        case .webAuthnCeremonyFailed(let failure, _, _, _): return .webAuthnCeremonyFailed(failure)
        case .unexpectedIdentity(let expected, let returned, _, _, _): return .unexpectedIdentity(expected: expected, returned: returned)
        case .unknown: return .unknown
        }
    }

    /// The equality `AuthSessionState.failed` uses: same case, same structured payload, same
    /// description and suggestion. The underlying error is not compared, because it cannot be.
    ///
    /// Deliberately not an `Equatable` conformance on `AuthClientError` itself: an `==` that
    /// ignores the underlying error would read as full equality to anyone catching the error.
    func isEquivalent(to other: AuthClientError) -> Bool {
        kind == other.kind
            && errorDescription == other.errorDescription
            && recoverySuggestion == other.recoverySuggestion
    }
}
