//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// Errors thrown by `AmplifyCognitoClient`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientError {

    /// The client's configuration is missing, unreadable, or incomplete.
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Secure storage could not be read or written. Usually transient, so an app should not
    /// show a sign-in screen in response to it.
    case storageUnavailable(StorageUnavailableReason, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The refresh token expired or was revoked, so this session needs a fresh sign-in. Other
    /// sessions are unaffected.
    case sessionExpired(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// An operation that needs a signed-in user pool user ran against a session without one: signed out, a
    /// guest, federated to the identity pool, or (for the operations on the signed-in user) waiting on a
    /// sign-in challenge.
    case notSignedIn(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A session ID was empty, too long, or contained a character outside `[A-Za-z0-9_-]`.
    case invalidSessionID(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Cognito no longer accepts the sign-in's challenge session (it expired, after about three minutes, or
    /// is otherwise invalid), so the challenge can never be answered: call `signIn` to start again.
    case challengeExpired(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The process's one system sheet is held, so nothing was presented. It is held by a hosted-UI sign-in,
    /// a hosted-UI sign-out page or a passkey ceremony (sign-in or registration), of another session or of
    /// this one. Also thrown when this session already has a hosted-UI sign-in in progress or queued, and when
    /// a `WebUIOptions.whenBrowserBusy` `.wait(timeout:)` expired before the sheet was free. `holder` is the
    /// session holding the sheet when the call was refused.
    case browserBusy(holder: SessionID, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A client was constructed with a session ID that is already live in this process under a different
    /// configuration: a different user pool, identity pool or keychain access group, or different settings
    /// (such as one handle passing `Options.configureUserPoolClient` and another none). Two handles on one
    /// session must agree, so the second construction throws rather than silently attaching. Also thrown by
    /// `signOutStoredSession` and `purgeStoredSession` when a client for the session is live in this process
    /// with a different user pool or identity pool: its records are that client's to change.
    case sessionConfigurationMismatch(SessionID, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A value supplied by the caller was invalid. `field` names it. The counterpart of Amplify
    /// core's `AuthError.validation`, thrown for example by
    /// `AuthClientTOTPSetupDetails.getSetupURI(appName:accountName:)`.
    case validation(field: String, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Cognito rejected the request. `code` says why, when the client recognises the service's
    /// exception (`nil` otherwise). The counterpart of Amplify core's `AuthError.service`, whose
    /// underlying error is the plugin's `AWSCognitoAuthError`: match on `code` here instead.
    case service(AuthClientServiceErrorCode?, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The caller is not allowed to perform the operation: for example, a wrong password, or a
    /// disabled user. The counterpart of Amplify core's `AuthError.notAuthorized`.
    case notAuthorized(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The operation is not valid in the session's current state: for example, `signIn` while this
    /// session is already signed in, or `confirmSignIn` with no sign-in in progress. The counterpart of
    /// Amplify core's `AuthError.invalidState`.
    case invalidState(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The user dismissed a system sheet the operation needed: the passkey sheet of a WebAuthn ceremony, the
    /// hosted UI's sign-in browser, or its sign-out page (the session then stays signed in). Also thrown when
    /// `cancelWebUISignIn()` or `resetSystemSheet()` closes the sheet. Nothing was changed; retrying is the
    /// user's choice.
    case userCancelled(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A local WebAuthn ceremony failed before Cognito was asked anything. The underlying error is the
    /// platform's `ASAuthorizationError`. Cognito's own WebAuthn rejections are `.service` instead.
    case webAuthnCeremonyFailed(AuthClientWebAuthnCeremonyFailure, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A hosted-UI sign-in returned a different user than the one asked for
    /// (`WebUIOptions.identityExpectation`), so nobody was signed in and nothing was stored. `expected` is
    /// the expectation that was not met (`nil` for `.distinctFromOtherSessions`); `returned` is the user
    /// that came back. Sign in again with `prompt: [.login]`, so the browser asks for credentials instead
    /// of reusing a saved sign-in.
    ///
    /// The strings never name either user, but the case's fields do, so its default printing
    /// (`print(error)`, `String(describing:)`, `dump`) shows the expected and returned user: log the strings,
    /// not the error, where user identifiers must not appear.
    case unexpectedIdentity(expected: String?, returned: AuthClientUser, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A failure that does not fall into the categories above.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension AuthClientError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .storageUnavailable(_, let description, _, _),
             .browserBusy(_, let description, _, _),
             .sessionConfigurationMismatch(_, let description, _, _),
             .validation(_, let description, _, _),
             .service(_, let description, _, _),
             .webAuthnCeremonyFailed(_, let description, _, _):
            return description
        case .unexpectedIdentity(_, _, let description, _, _):
            return description
        case .configuration(let description, _, _),
             .sessionExpired(let description, _, _),
             .notSignedIn(let description, _, _),
             .invalidSessionID(let description, _, _),
             .challengeExpired(let description, _, _),
             .notAuthorized(let description, _, _),
             .invalidState(let description, _, _),
             .userCancelled(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .storageUnavailable(_, _, let suggestion, _),
             .browserBusy(_, _, let suggestion, _),
             .sessionConfigurationMismatch(_, _, let suggestion, _),
             .validation(_, _, let suggestion, _),
             .service(_, _, let suggestion, _),
             .webAuthnCeremonyFailed(_, _, let suggestion, _):
            return suggestion
        case .unexpectedIdentity(_, _, _, let suggestion, _):
            return suggestion
        case .configuration(_, let suggestion, _),
             .sessionExpired(_, let suggestion, _),
             .notSignedIn(_, let suggestion, _),
             .invalidSessionID(_, let suggestion, _),
             .challengeExpired(_, let suggestion, _),
             .notAuthorized(_, let suggestion, _),
             .invalidState(_, let suggestion, _),
             .userCancelled(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .storageUnavailable(_, _, _, let error),
             .browserBusy(_, _, _, let error),
             .sessionConfigurationMismatch(_, _, _, let error),
             .validation(_, _, _, let error),
             .service(_, _, _, let error),
             .webAuthnCeremonyFailed(_, _, _, let error):
            return error
        case .unexpectedIdentity(_, _, _, _, let error):
            return error
        case .configuration(_, _, let error),
             .sessionExpired(_, _, let error),
             .notSignedIn(_, _, let error),
             .invalidSessionID(_, _, let error),
             .challengeExpired(_, _, let error),
             .notAuthorized(_, _, let error),
             .invalidState(_, _, let error),
             .userCancelled(_, _, let error),
             .unknown(_, _, let error):
            return error
        }
    }

    /// Builds an error from its parts, as `AmplifyError` requires. An `AuthClientError` passed as `error` is
    /// returned as it is, ignoring the two strings; anything else is wrapped in `.unknown` with them.
    public init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error?
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }
}

extension AuthClientError {

    /// Whether the user dismissed a system sheet.
    var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        }
        return false
    }
}
