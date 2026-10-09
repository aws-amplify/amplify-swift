//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import Foundation
import InternalAWSCognitoAuth

// Engine types -> client types. The only client file that names both an `Engine…` type and a
// client type, so no engine type reaches a public API.
//
// Every mapper is an exhaustive `switch` with no `default:`, so a new engine case does not compile until it
// is mapped. MFA, factor and flow types map **case to case, never through `rawValue`**: in the engine,
// `rawValue` is the Cognito string (`SMS_MFA`), in the client it is the public name (`sms`).

// MARK: Sign-in steps

extension AuthClientSignInStep {

    /// Case for case, in declaration order. `.done` maps to `.done`; the engine adapter
    /// reports a finished sign-in as `EngineStepResult.done`, not as a step.
    init(_ step: EngineSignInStep) {
        switch step {
        case .confirmSignInWithSMSMFACode(let details, let info):
            self = .confirmSignInWithSMSMFACode(AuthClientCodeDeliveryDetails(details), info)
        case .confirmSignInWithCustomChallenge(let info):
            self = .confirmSignInWithCustomChallenge(info)
        case .confirmSignInWithNewPassword(let info):
            self = .confirmSignInWithNewPassword(info)
        case .confirmSignInWithPassword:
            self = .confirmSignInWithPassword
        case .confirmSignInWithTOTPCode:
            self = .confirmSignInWithTOTPCode
        case .continueSignInWithTOTPSetup(let details):
            self = .continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(details))
        case .continueSignInWithMFASelection(let types):
            self = .continueSignInWithMFASelection(Set(types.map(AuthClientMFAType.init)))
        case .continueSignInWithEmailMFASetup:
            self = .continueSignInWithEmailMFASetup
        case .continueSignInWithMFASetupSelection(let types):
            self = .continueSignInWithMFASetupSelection(Set(types.map(AuthClientMFAType.init)))
        case .confirmSignInWithOTP(let details):
            self = .confirmSignInWithOTP(AuthClientCodeDeliveryDetails(details))
        case .continueSignInWithFirstFactorSelection(let factors):
            self = .continueSignInWithFirstFactorSelection(Set(factors.map(AuthClientFactorType.init)))
        case .resetPassword(let info):
            self = .resetPassword(info)
        case .confirmSignUp(let info):
            self = .confirmSignUp(info)
        case .done:
            self = .done
        }
    }
}

extension AuthClientCodeDeliveryDetails {

    /// The engine carries the attribute as its Cognito name; the client names it with its own key.
    init(_ details: EngineCodeDeliveryDetails) {
        self.init(
            destination: AuthClientDeliveryDestination(details.destination),
            attributeKey: details.attributeKey.map(AuthClientUserAttributeKey.init(cognitoName:))
        )
    }
}

extension AuthClientDeliveryDestination {

    init(_ destination: EngineDeliveryDestination) {
        switch destination {
        case .email(let value): self = .email(value)
        case .phone(let value): self = .phone(value)
        case .sms(let value): self = .sms(value)
        case .unknown(let value): self = .unknown(value)
        }
    }
}

extension AuthClientTOTPSetupDetails {

    init(_ details: EngineTOTPSetupDetails) {
        self.init(sharedSecret: details.sharedSecret, username: details.username)
    }
}

extension AuthClientMFAType {

    init(_ type: EngineMFAType) {
        switch type {
        case .sms: self = .sms
        case .totp: self = .totp
        case .email: self = .email
        }
    }
}

extension AuthClientFactorType {

    init(_ factor: EngineAuthFactorType) {
        switch factor {
        case .password: self = .password
        case .passwordSRP: self = .passwordSRP
        case .smsOTP: self = .smsOTP
        case .emailOTP: self = .emailOTP
        #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn:
            guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
                // A `.webAuthn` value only exists where the case is available.
                preconditionFailure("EngineAuthFactorType.webAuthn outside its availability")
            }
            self = .webAuthn
        #endif
        }
    }
}

// MARK: Client -> engine: the sign-in request

extension EngineAuthFactorType {

    init(_ factor: AuthClientFactorType) {
        switch factor {
        case .password: self = .password
        case .passwordSRP: self = .passwordSRP
        case .smsOTP: self = .smsOTP
        case .emailOTP: self = .emailOTP
        #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn:
            guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
                // A `.webAuthn` value only exists where the case is available.
                preconditionFailure("AuthClientFactorType.webAuthn outside its availability")
            }
            self = .webAuthn
        #endif
        }
    }
}

extension EngineAuthFlowType {

    /// The engine's deprecated `.custom` has no client case, so it is never produced.
    init(_ flow: AuthClientAuthFlowType) {
        switch flow {
        case .userSRP: self = .userSRP
        case .customWithSRP: self = .customWithSRP
        case .customWithoutSRP: self = .customWithoutSRP
        case .userPassword: self = .userPassword
        case .userAuth(let preferredFirstFactor):
            self = .userAuth(preferredFirstFactor: preferredFirstFactor.map(EngineAuthFactorType.init))
        }
    }
}

// MARK: Tokens and credentials

extension AuthClientUserPoolTokens {

    /// The deprecated `expiration` is dropped; read the token's `exp` claim instead.
    init(_ tokens: EngineUserPoolTokens) {
        self.init(idToken: tokens.idToken, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
    }
}

extension CognitoAWSCredentials {

    init(_ credentials: EngineAWSCredentials) {
        self.init(
            accessKeyId: credentials.accessKeyId,
            secretAccessKey: credentials.secretAccessKey,
            sessionToken: credentials.sessionToken,
            expiration: credentials.expiration
        )
    }
}

// MARK: The payload

extension CredentialSummary {

    /// Who and what a payload holds. A federated payload has no user: no federated user is invented (`userId = identityId` would let `isSamePrincipal` equate a
    /// `sub` with an identity ID).
    init(_ credentials: AmplifyCredentials) {
        switch credentials {
        case .userPoolOnly(let signedInData):
            self.init(kind: .userPoolOnly, username: signedInData.username, userId: signedInData.userId)
        case .userPoolAndIdentityPool(let signedInData, let identityId, _):
            self.init(
                kind: .userPoolAndIdentityPool,
                username: signedInData.username,
                userId: signedInData.userId,
                identityId: identityId
            )
        case .identityPoolOnly(let identityId, _):
            self.init(kind: .guest, username: nil, userId: nil, identityId: identityId)
        case .identityPoolWithFederation(_, let identityId, _):
            self.init(kind: .federated, username: nil, userId: nil, identityId: identityId)
        case .noCredentials:
            self.init(kind: .signedOut, username: nil, userId: nil)
        }
    }
}

extension AmplifyCredentials {

    /// The user pool tokens, for the two kinds that have them.
    var userPoolTokens: EngineUserPoolTokens? {
        switch self {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            return signedInData.cognitoUserPoolTokens
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return nil
        }
    }

    /// The identity pool's AWS credentials, for the three kinds that have them.
    var awsCredentials: EngineAWSCredentials? {
        switch self {
        case .userPoolAndIdentityPool(_, _, let credentials),
             .identityPoolOnly(_, let credentials),
             .identityPoolWithFederation(_, _, let credentials):
            return credentials
        case .userPoolOnly, .noCredentials:
            return nil
        }
    }
}

// MARK: Errors

extension AuthClientServiceErrorCode {

    /// Case for case: the same 34 cases, in the same order.
    init(_ code: EngineServiceErrorCode) {
        switch code {
        case .userNotFound: self = .userNotFound
        case .userNotConfirmed: self = .userNotConfirmed
        case .usernameExists: self = .usernameExists
        case .aliasExists: self = .aliasExists
        case .codeDelivery: self = .codeDelivery
        case .codeMismatch: self = .codeMismatch
        case .codeExpired: self = .codeExpired
        case .invalidParameter: self = .invalidParameter
        case .invalidPassword: self = .invalidPassword
        case .limitExceeded: self = .limitExceeded
        case .mfaMethodNotFound: self = .mfaMethodNotFound
        case .softwareTokenMFANotEnabled: self = .softwareTokenMFANotEnabled
        case .passwordResetRequired: self = .passwordResetRequired
        case .resourceNotFound: self = .resourceNotFound
        case .failedAttemptsLimitExceeded: self = .failedAttemptsLimitExceeded
        case .requestLimitExceeded: self = .requestLimitExceeded
        case .lambda: self = .lambda
        case .deviceNotTracked: self = .deviceNotTracked
        case .errorLoadingUI: self = .errorLoadingUI
        case .userCancelled: self = .userCancelled
        case .invalidAccountTypeException: self = .invalidAccountTypeException
        case .network: self = .network
        case .smsRole: self = .smsRole
        case .emailRole: self = .emailRole
        case .externalServiceException: self = .externalServiceException
        case .limitExceededException: self = .limitExceededException
        case .resourceConflictException: self = .resourceConflictException
        case .webAuthnChallengeNotFound: self = .webAuthnChallengeNotFound
        case .webAuthnClientMismatch: self = .webAuthnClientMismatch
        case .webAuthnNotSupported: self = .webAuthnNotSupported
        case .webAuthnNotEnabled: self = .webAuthnNotEnabled
        case .webAuthnOriginNotAllowed: self = .webAuthnOriginNotAllowed
        case .webAuthnRelyingPartyMismatch: self = .webAuthnRelyingPartyMismatch
        case .webAuthnConfigurationMissing: self = .webAuthnConfigurationMissing
        }
    }
}

extension AuthClientError {

    /// One exhaustive switch. The description and recovery suggestion are the engine's,
    /// which are the plugin's strings verbatim (pinned by its error-catalogue golden), read through the same accessors `AuthError` has, so
    /// `.unknown` keeps the plugin's "Unexpected error occurred with message: …" prefix. The engine error is
    /// the underlying error, so diagnostics lose nothing; its type is `package`, so it is never exposed by
    /// name.
    ///
    /// `.service` carries the service code the engine put underneath (`EngineServiceErrorCode`), or `nil`
    /// when the service error is one the client does not recognise. The exceptions are checked first, in
    /// this order, so none of them is ever `.service`:
    /// - an `AuthClientError` underneath is the client's own, handed to the engine and back (the sheet
    ///   lease's `.browserBusy(holder:)`, for example): it is itself;
    /// - a local WebAuthn ceremony's failure, the platform's `ASAuthorizationError` underneath:
    ///   `.canceled` (the user closed the sheet) is `.userCancelled`, code
    ///   1006 (registration matched an excluded credential) `.webAuthnCeremonyFailed(.credentialAlreadyExists)`,
    ///   any other `.webAuthnCeremonyFailed(.failed)`, each with the `ASAuthorizationError` as the underlying
    ///   error. Whether the calling task was cancelled is the caller's to decide: the caller cancelling its own
    ///   task is `CancellationError`, which this initializer never sees;
    /// - ceremony options the engine could not read, or a result it could not encode
    ///   (`AnyWebAuthnCredentialError` underneath): `.webAuthnCeremonyFailed(.invalidCredential)`;
    /// - `EngineServiceErrorCode.userCancelled` (the hosted UI's browser closed): `.userCancelled`. The client
    ///   reports a user's cancellation in one shape only.
    ///
    /// Two engine recovery suggestions are replaced with client text, since neither helps an app: the empty one
    /// of a `.configuration` (`clientConfigurationSuggestion`), and, on a `.service` with no service code, an
    /// empty one or the engine's "report a bug" text (`clientServiceSuggestion`), when it carries an underlying
    /// error. Such a service error is usually a network failure or an answer the client does not recognise, not a
    /// bug. One with nothing underneath is the engine's own state (`FetchSessionError.noCredentialsToRefresh`),
    /// which no retry fixes, and keeps its text.
    ///
    /// Two service failures are told apart first. A response that is not JSON (such as an HTML error page from the
    /// service's edge: Foundation's `NSCocoaErrorDomain` 3840, which the SDK surfaces without retrying) stays
    /// `.service` with no code, with the recovery suggestion `unreadableServiceResponseSuggestion`: it is a
    /// temporary service problem, which the app may retry, as any temporary service failure. A `DecodingError`
    /// underneath (JSON that does not match the model, more likely a client bug) keeps the engine's suggestion,
    /// "report a bug" included.
    ///
    /// Engine texts that name the plugin's calls are given the client's names (`clientText(_:)`): the recovery
    /// suggestions in `clientRecoverySuggestions` ("Invoke Auth.signIn …" becomes "Call signIn …"), and
    /// `Amplify.MFAType.<type>` in a text becomes `AuthClientMFAType.<type>`. The engine's strings themselves are
    /// unchanged: they are the plugin's, which its error-catalogue golden pins.
    init(engine error: EngineAuthError) {
        let description = Self.clientText(error.errorDescription)
        let suggestion = Self.clientText(error.recoverySuggestion)
        switch error {
        case .configuration:
            self = .configuration(
                description,
                suggestion.isEmpty ? Self.clientConfigurationSuggestion : suggestion,
                error
            )
        case .service(_, _, let underlying):
            if let clientError = underlying as? AuthClientError {
                self = clientError
                return
            }
            if let ceremonyFailure = Self(webAuthnCeremony: underlying, description, suggestion) {
                self = ceremonyFailure
                return
            }
            if Self.isUnreadableServiceResponse(underlying) {
                self = .service(nil, description, Self.unreadableServiceResponseSuggestion, error)
                return
            }
            let code = (underlying as? EngineServiceErrorCode).map(AuthClientServiceErrorCode.init)
            if code == .userCancelled {
                // Cancellation has one shape in the client, whatever sheet the user closed.
                self = .userCancelled(description, suggestion, error)
            } else if code == nil, let underlying, !(underlying is DecodingError), Self.isUnhelpfulServiceSuggestion(suggestion) {
                self = .service(nil, description, Self.clientServiceSuggestion, error)
            } else {
                self = .service(code, description, suggestion, error)
            }
        case .unknown:
            self = .unknown(description, suggestion, error)
        case .validation(let field, _, _, _):
            self = .validation(field: field, description, suggestion, error)
        case .notAuthorized:
            self = .notAuthorized(description, suggestion, error)
        case .invalidState:
            self = .invalidState(description, suggestion, error)
        case .signedOut:
            self = .notSignedIn(description, suggestion, error)
        case .sessionExpired:
            self = .sessionExpired(description, suggestion, error)
        }
    }

    /// The engine's recovery suggestions that name the plugin's `Auth.*` calls, keyed by the engine's exact text,
    /// with the client's text for each. The first is `AuthorizationError.sessionExpired`'s, which reaches this
    /// initializer wherever an authorization error is mapped as it is (the guest and federation paths; the refresh
    /// path reads `.sessionExpired` itself and uses the core's text). The others are `AuthPluginErrorConstants` that
    /// the engine does not use today; they are mapped so that an engine path that starts using one
    /// still names the client's calls.
    static let clientRecoverySuggestions: [String: String] = [
        "Invoke Auth.signIn to re-authenticate the user":
            "Call signIn to sign the user in again.",
        "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool":
            "Call signIn to sign a user in, or enable unauthenticated access in the Cognito identity pool.",
        "Call Auth.signIn to sign in a user and then call Auth.fetchSession":
            "Call signIn to sign a user in, then call fetchAuthSession.",
        "Get the current user Auth.getCurrentUser() and make the request":
            "Call getCurrentUser to get the signed-in user, then make the request again."
    ]

    /// How the engine names an MFA type in a text (`EngineMFAType.legacyDescription(of:)`, in the MFA setup
    /// refusal "Cannot initiate MFA setup from available Types: [Amplify.MFAType.totp]"), and the client's name.
    static let engineMFATypePrefix = "Amplify.MFAType."
    static let clientMFATypePrefix = "AuthClientMFAType."

    /// An engine description or recovery suggestion, with the plugin's call and type names replaced by the
    /// client's (`init(engine:)`).
    static func clientText(_ engineText: String) -> String {
        if let replacement = clientRecoverySuggestions[engineText] {
            return replacement
        }
        return engineText.replacingOccurrences(of: engineMFATypePrefix, with: clientMFATypePrefix)
    }

    /// The recovery suggestion of an engine `.configuration` that has none.
    static let clientConfigurationSuggestion =
        "Check the client's configuration: the auth section of amplify_outputs.json, or the AuthClientConfiguration passed in."

    /// The recovery suggestion of a `.service` with no service code whose engine suggestion is empty or asks for
    /// a bug report.
    static let clientServiceSuggestion =
        "A network or service problem occurred. Check the connection and retry the operation."

    /// How the engine's "report a bug" recovery text (`EngineErrorMessages.reportBugToAWS`) begins.
    static let reportBugPrefix = "There is a possibility that there is a bug"

    /// Whether a service error's engine recovery suggestion says nothing an app can act on.
    static func isUnhelpfulServiceSuggestion(_ suggestion: String) -> Bool {
        suggestion.isEmpty || suggestion.hasPrefix(reportBugPrefix)
    }

    /// The recovery suggestion of a `.service` whose response body was not JSON (`isUnreadableServiceResponse`).
    static let unreadableServiceResponseSuggestion =
        "The service returned a response that could not be read, usually a temporary problem at the service. Retry the operation."

    /// Whether the error under a service failure says the response body is not JSON: Foundation's JSON reader's
    /// `NSCocoaErrorDomain` 3840 (`NSPropertyListReadCorruptError`).
    static func isUnreadableServiceResponse(_ underlying: Error?) -> Bool {
        guard let underlying, !(underlying is DecodingError) else {
            return false
        }
        let error = underlying as NSError
        return error.domain == NSCocoaErrorDomain && error.code == NSPropertyListReadCorruptError
    }

    /// A local WebAuthn ceremony's failure, from the error the engine put underneath, or `nil` if it is not
    /// one (`init(engine:)`).
    private init?(webAuthnCeremony underlying: Error?, _ description: String, _ suggestion: String) {
        #if os(iOS) || os(macOS) || os(visionOS)
        if let authorization = underlying as? ASAuthorizationError {
            if authorization.code == .canceled {
                self = .userCancelled(description, suggestion, authorization)
            } else if authorization.code.rawValue == Self.matchedExcludedCredentialCode {
                self = .webAuthnCeremonyFailed(.credentialAlreadyExists, description, suggestion, authorization)
            } else {
                self = .webAuthnCeremonyFailed(.failed, description, suggestion, authorization)
            }
            return
        }
        // Only declared where WebAuthn exists (`AWSWebAuthCredentialsModels.swift`).
        if let underlying, underlying is AnyWebAuthnCredentialError {
            self = .webAuthnCeremonyFailed(.invalidCredential, description, suggestion, underlying)
            return
        }
        #endif
        return nil
    }

    /// `ASAuthorizationError.matchedExcludedCredential` (iOS 18, macOS 15), by value, as the engine checks it.
    static let matchedExcludedCredentialCode = 1_006

    /// A failure answering a challenge (`RespondToAuthChallenge`), for the confirm path.
    ///
    /// Cognito rejects an answer to a challenge session it no longer accepts (expired after about 3
    /// minutes, or otherwise invalid) with `NotAuthorizedException`. The engine maps that exception to
    /// `.notAuthorized` with Cognito's message, or the engine's fallback text when there is none. The
    /// operation (this initializer is only used on the confirm path) and the case identify it, and the
    /// message tells the `NotAuthorizedException`s on this path apart:
    /// - an invalid or expired session ("Invalid session for the user, session is expired.", "Invalid
    ///   session for the user."): the challenge can never be answered, so `.challengeExpired`, and the
    ///   attempt is dropped;
    /// - no message (the engine's fallback text): treated the same way. Restarting a sign-in always works;
    ///   retrying a dead challenge never does;
    /// - anything else, such as "Incorrect username or password." (a wrong password on a password
    ///   challenge): `.notAuthorized`, which stays retryable.
    ///
    /// Keying on the exception's type needs the engine to keep it as the underlying error. It keeps none
    /// today, and adding it changes the plugin's `AuthError.notAuthorized` (its frozen error catalogue
    /// and three plugin tests), so that is left for a separate change. Everything else maps as `init(engine:)` does.
    ///
    /// `rejectedByUserPool` is whether the answer's `RespondToAuthChallenge` itself failed with the user pool's
    /// `NotAuthorizedException` (the engine keeps no exception underneath, so the operation's user pool records
    /// it). An expired challenge needs both the type and the message; a `.notAuthorized` from anywhere else on
    /// the confirm path, such as the identity pool step after the challenge, is never `challengeExpired`.
    init(engineConfirmingSignIn error: EngineAuthError, rejectedByUserPool: Bool) {
        if rejectedByUserPool, case .notAuthorized(let message, _, _) = error, Self.isInvalidChallengeSession(message) {
            self = .challengeExpired(
                error.errorDescription,
                "The sign-in's challenge can no longer be answered. Call signIn to start a new sign-in.",
                error
            )
        } else {
            self.init(engine: error)
        }
    }

    /// What Cognito says of an expired challenge session.
    static let expiredSessionPhrase = "session is expired"
    /// What Cognito says of a challenge session it does not accept, expired or not.
    static let invalidSessionPhrase = "Invalid session for the user"
    /// The engine's description for a `NotAuthorizedException` with no message
    /// (`NotAuthorizedException.fallbackDescription`).
    static let messagelessNotAuthorized = "Not authorized error."

    /// Whether a `.notAuthorized` message on the confirm path means the challenge session is dead.
    static func isInvalidChallengeSession(_ message: String) -> Bool {
        if message == messagelessNotAuthorized {
            return true
        }
        return [expiredSessionPhrase, invalidSessionPhrase].contains {
            message.range(of: $0, options: .caseInsensitive) != nil
        }
    }
}

extension EngineSignOutOutcome {

    /// The sign-out failures, mapped. The refresh and access tokens they carry are dropped (not
    /// exposed).
    init(
        revokeFailure: EngineRevokeTokenFailure?,
        globalSignOutFailure: EngineGlobalSignOutFailure?,
        hostedUIFailure: EngineHostedUISignOutFailure? = nil
    ) {
        self.init(
            revokeError: revokeFailure.map { AuthClientError(engine: $0.error) },
            globalSignOutError: globalSignOutFailure.map { AuthClientError(engine: $0.error) },
            hostedUIError: hostedUIFailure.map { AuthClientError(engine: $0.error) }
        )
    }
}
