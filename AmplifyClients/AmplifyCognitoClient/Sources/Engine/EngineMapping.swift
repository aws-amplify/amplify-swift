//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
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
    /// an engine `.unknown`'s description keeps the plugin's "Unexpected error occurred with message: …" prefix, unless
    /// it is replaced below. The engine error is
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
    /// A transport failure (`transportFailure(_:wrapping:)`: a network failure, a response that could not be read,
    /// another URL loading failure) reads the same whichever engine case carries it, a code-less `.service` or an
    /// `.unknown`: the client's description and suggestion, whatever the engine's were. A network failure has the
    /// network error itself underneath (the `URLError`, or the CFNetwork or POSIX error), not the engine's error
    /// over it, so an app can match it as the core's fallbacks report it. A response that is not JSON (such as an
    /// HTML error page from the service's edge: Foundation's `NSCocoaErrorDomain` 3840, which the SDK surfaces
    /// without retrying) is one that could not be read: a temporary service problem, which the app may retry. A
    /// `DecodingError` underneath (JSON that does not match the model, more likely a client bug) is not a transport
    /// failure, and keeps the engine's suggestion, "report a bug" included.
    ///
    /// Two engine recovery suggestions are replaced with client text, since neither helps an app: the empty one
    /// of a `.configuration` (`clientConfigurationSuggestion`), and, on any other `.service` with no service code,
    /// an empty one or the engine's "report a bug" text, "This should not happen." first or not (the passkey calls'
    /// fallback), with `clientServiceSuggestion`, when it carries an underlying error; an empty description becomes
    /// `emptyServiceFailureDescription`. Such a service error is usually an answer the client does not recognise, not
    /// a bug. One with nothing underneath is the engine's own state (`FetchSessionError.noCredentialsToRefresh`),
    /// which no retry fixes, and keeps its text.
    ///
    /// A Cognito failure the engine reports as `.unknown` (where the plugin keeps `AuthError.unknown`) is `.service`
    /// with no code, as that case's documentation says, with the engine's description and a recovery suggestion that
    /// fits it in place of the engine's "report a bug" text (`serviceFailureSuggestion(underlying:cause:)`): an error
    /// status the SDK does not model, or Cognito's `InternalErrorException`. The engine keeps nothing under the
    /// latter, so only `cause`, the failure the engine error was made from, tells it apart. Every call that reaches
    /// Cognito passes it: the sign-in flows' state-machine errors hold the exception (`serviceException(in:)`: a
    /// `USER_AUTH`, auto or device SRP sign-in's authentication error, a passkey sign-in's `WebAuthnError.service`), and
    /// for `deleteUser`, a sign-out's revoke and global sign-out, and the passkey credential calls, the engine carries
    /// it beside the engine error.
    ///
    /// Engine texts that name the plugin's calls are given the client's names (`clientText(_:)`): the recovery
    /// suggestions in `clientRecoverySuggestions` ("Invoke Auth.signIn …" becomes "Call signIn …"), and
    /// `Amplify.MFAType.<type>` in a text becomes `AuthClientMFAType.<type>`. The engine's strings themselves are
    /// unchanged: they are the plugin's, which its error-catalogue golden pins.
    init(engine error: EngineAuthError, cause: Error? = nil) {
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
            let code = (underlying as? EngineServiceErrorCode).map(AuthClientServiceErrorCode.init)
            if code == .userCancelled {
                // Cancellation has one shape in the client, whatever sheet the user closed.
                self = .userCancelled(description, suggestion, error)
            } else if code == nil, let underlying, let transport = Self.transportFailure(underlying, wrapping: error) {
                self = transport
            } else if code == nil, let underlying, !(underlying is DecodingError), Self.isUnhelpfulServiceSuggestion(suggestion) {
                self = .service(
                    nil,
                    description.isEmpty ? Self.emptyServiceFailureDescription : description,
                    Self.clientServiceSuggestion,
                    error
                )
            } else {
                self = .service(code, description, suggestion, error)
            }
        case .unknown(_, let underlying):
            // A transport failure (a network failure, a response that could not be read, a
            // URL loading failure) is a service failure an app may retry, as the refresh path reports it, not "a
            // bug". The sign-in flows' state machines report it as `.unknown` with an empty message.
            if let underlying, let transport = Self.transportFailure(underlying, wrapping: error) {
                self = transport
            } else if let serviceSuggestion = Self.serviceFailureSuggestion(underlying: underlying, cause: cause) {
                self = .service(nil, description, serviceSuggestion, error)
            } else {
                self = .unknown(description, suggestion, error)
            }
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

    /// `init(engine:cause:)` of `failure`'s engine error, with `failure` as the cause.
    init(engineFailure failure: any EngineAuthErrorConvertible) {
        self.init(engine: failure.engineError, cause: failure as? Error)
    }

    /// The engine's recovery suggestions that name the plugin's `Auth.*` calls or the plugin itself, keyed by the
    /// engine's exact text, with the client's text for each. The first is `AuthorizationError.sessionExpired`'s, which
    /// reaches this initializer wherever an authorization error is mapped as it is (the guest and federation paths;
    /// the refresh path reads `.sessionExpired` itself and uses the core's text). The last is
    /// `AuthPluginErrorConstants.configurationError`, the suggestion of either pool's invalid-configuration exception
    /// (`InvalidUserPoolConfigurationException`, `InvalidIdentityPoolConfigurationException`) and of the engine's own
    /// configuration errors. The others are `AuthPluginErrorConstants` that the engine does not use today; they are
    /// mapped so that an engine path that starts using one still names the client's calls.
    static let clientRecoverySuggestions: [String: String] = [
        "Invoke Auth.signIn to re-authenticate the user":
            "Call signIn to sign the user in again.",
        "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool":
            "Call signIn to sign a user in, or enable unauthenticated access in the Cognito identity pool.",
        "Call Auth.signIn to sign in a user and then call Auth.fetchSession":
            "Call signIn to sign a user in, then call fetchAuthSession.",
        "Get the current user Auth.getCurrentUser() and make the request":
            "Call getCurrentUser to get the signed-in user, then make the request again.",
        "Make sure that the amplify configuration passed to Auth plugin is valid":
            "Check the user pool's settings (device tracking, for the device calls), the identity pool's settings, and "
                + "the client's configuration."
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

    /// How the client reports a transport failure `underlying`, or `nil` if it isn't one. A network failure has
    /// `underlying` itself underneath; the others have `wrapping` (the engine's error, or `underlying` itself):
    /// - a network failure (`isNetworkFailure`): `networkFailure`'s texts;
    /// - a response that could not be read (`isUnreadableResponse`): `.service` with no code,
    ///   `unreadableResponseDescription` and `unreadableServiceResponseSuggestion`, as the refresh path suggests;
    /// - any other URL loading failure but a cancellation (App Transport Security, say): `.service` with no code,
    ///   `emptyServiceFailureDescription` and the client's network-or-service suggestion.
    static func transportFailure(_ underlying: Error, wrapping: Error) -> AuthClientError? {
        if isNetworkFailure(underlying) {
            return .service(nil, networkFailureDescription, clientServiceSuggestion, underlying)
        }
        if isUnreadableResponse(underlying) {
            return .service(nil, unreadableResponseDescription, unreadableServiceResponseSuggestion, wrapping)
        }
        let nsError = underlying as NSError
        if [NSURLErrorDomain, cfNetworkErrorDomain].contains(nsError.domain), nsError.code != NSURLErrorCancelled,
           !(underlying is CancellationError) {
            return .service(nil, emptyServiceFailureDescription, clientServiceSuggestion, wrapping)
        }
        return nil
    }

    /// `transportFailure(error, wrapping: error)`, for an error the engine did not wrap: what the core's fallbacks
    /// report for a transport failure.
    static func transportFailure(_ error: Error) -> AuthClientError? {
        guard !(error is AuthClientError), !(error is EngineAuthError), !(error is CancellationError) else {
            return nil
        }
        return transportFailure(error, wrapping: error)
    }

    /// The description of a response that arrived but could not be read (`isUnreadableResponse`).
    static let unreadableResponseDescription = "The service returned a response that could not be read."

    /// Whether `error` says a response arrived but could not be read: a body that is not JSON
    /// (`isUnreadableServiceResponse`), or URL loading's `badServerResponse` or `cannotParseResponse`.
    static func isUnreadableResponse(_ error: Error) -> Bool {
        if isUnreadableServiceResponse(error) {
            return true
        }
        let nsError = error as NSError
        return [NSURLErrorDomain, cfNetworkErrorDomain].contains(nsError.domain)
            && [NSURLErrorBadServerResponse, NSURLErrorCannotParseResponse].contains(nsError.code)
    }

    /// The description of a network failure (`isNetworkFailure`). It does not say the request never reached the
    /// service: a timed-out or lost connection, or an SDK retry that failed offline, may follow a request the service
    /// acted on, whose answer was lost.
    static let networkFailureDescription = "A network problem stopped the request. It may not have reached the service."

    /// The description of a URL loading failure that is neither a network failure nor a response that could not be
    /// read, and of any other code-less service failure whose engine description is empty (a revoke's).
    static let emptyServiceFailureDescription = "The service request failed."

    /// The descriptions the client gives a code-less service failure it describes itself: `transportFailure`'s,
    /// and the empty engine description's replacement.
    static let clientServiceFailureDescriptions: Set<String> = [
        networkFailureDescription,
        unreadableResponseDescription,
        emptyServiceFailureDescription
    ]

    /// Whether `error` is a network failure: the request may not have reached the service, or its answer was lost. A
    /// URL loading failure of `networkURLErrorCodes` (offline, a failed DNS lookup, a refused, lost or timed-out
    /// connection, a failed secure connection), in `NSURLErrorDomain` or `kCFErrorDomainCFNetwork`, a CFNetwork
    /// host-lookup failure, or a socket error of the POSIX domain that means the network or host is unreachable, the
    /// connection was refused, reset or not made, or it timed out. A failure about a response that did arrive
    /// (`badServerResponse`, `cannotParseResponse`), App Transport Security, authentication, or a cancellation, is not
    /// one. The caller's own cancellation is `CancellationError`.
    static func isNetworkFailure(_ error: Error?) -> Bool {
        guard let error, !(error is CancellationError), !(error is AuthClientError), !(error is EngineAuthError) else {
            return false
        }
        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            return networkURLErrorCodes.contains(nsError.code)
        case Self.cfNetworkErrorDomain:
            return networkURLErrorCodes.contains(nsError.code) || cfNetworkHostLookupCodes.contains(nsError.code)
        case NSPOSIXErrorDomain:
            return networkPOSIXCodes.contains(Int32(truncatingIfNeeded: nsError.code))
        default:
            return false
        }
    }

    /// The URL loading errors `isNetworkFailure` counts: the request may not have reached the service, or its answer
    /// was lost.
    static let networkURLErrorCodes: Set<Int> = [
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive,
        NSURLErrorDataNotAllowed,
        NSURLErrorSecureConnectionFailed
    ]

    /// CFNetwork's host-lookup errors, by value: `kCFHostErrorHostNotFound` and `kCFHostErrorUnknown`.
    static let cfNetworkHostLookupCodes: Set<Int> = [1, 2]

    /// CFNetwork's error domain, `kCFErrorDomainCFNetwork`, by value.
    static let cfNetworkErrorDomain = "kCFErrorDomainCFNetwork"

    /// The POSIX errors `isNetworkFailure` counts.
    static let networkPOSIXCodes: Set<Int32> = [
        ECONNREFUSED, ECONNRESET, ECONNABORTED, ENOTCONN, ETIMEDOUT, ENETDOWN, ENETUNREACH, ENETRESET,
        EHOSTDOWN, EHOSTUNREACH
    ]

    /// How the engine's "report a bug" recovery text (`EngineErrorMessages.reportBugToAWS`) begins.
    static let reportBugPrefix = "There is a possibility that there is a bug"

    /// What the engine puts before that text when it says the failure should not happen
    /// (`EngineErrorMessages.shouldNotHappenReportBugToAWS`, and the passkey calls' fallback, `WebAuthnError.unknown`).
    static let shouldNotHappenPrefix = "This should not happen. "

    /// Whether a service error's engine recovery suggestion says nothing an app can act on: empty, or a request for a
    /// bug report, with or without "This should not happen." before it.
    static func isUnhelpfulServiceSuggestion(_ suggestion: String) -> Bool {
        suggestion.isEmpty || suggestion.hasPrefix(reportBugPrefix) || suggestion.hasPrefix(shouldNotHappenPrefix + reportBugPrefix)
    }

    /// The recovery suggestion of a response that could not be read (`isUnreadableResponse`), such as a body that is
    /// not JSON.
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

    /// The recovery suggestion of a Cognito failure the service itself reported as its own: an
    /// `InternalErrorException`, or a 5xx status the SDK does not model.
    static let serviceFaultSuggestion =
        "The service could not complete the request, usually a temporary problem at the service. Retry the operation."

    /// The recovery suggestion of an error status below 500 that the SDK does not model: Cognito refused the
    /// request with an error this client does not recognise.
    static let unrecognisedServiceErrorSuggestion =
        "The service refused the request with an error this client does not recognise. The description has the "
            + "service's status and message: check the request against it before retrying."

    /// What an engine `.unknown` that Cognito reported suggests in place of the engine's "report a bug" text, or
    /// `nil` if it is not one: an error status the SDK does not model (`UnknownAWSHTTPServiceError`, which the
    /// engine keeps `underlying`) by its status, and either pool's `InternalErrorException`, found in `cause`
    /// (`serviceException(in:)`).
    static func serviceFailureSuggestion(underlying: Error?, cause: Error?) -> String? {
        if let unmodelled = underlying as? UnknownAWSHTTPServiceError {
            return unmodelled.httpResponse.statusCode.rawValue >= 500
                ? serviceFaultSuggestion
                : unrecognisedServiceErrorSuggestion
        }
        switch cause.map(serviceException(in:)) {
        case is AWSCognitoIdentityProvider.InternalErrorException, is AWSCognitoIdentity.InternalErrorException:
            return serviceFaultSuggestion
        default:
            return nil
        }
    }

    /// The service's error at the root of an engine failure: the engine's state-machine errors carry it in their
    /// `.service` cases. Anything else is itself.
    static func serviceException(in failure: Error) -> Error {
        switch failure {
        case SignInError.service(let error), AuthorizationError.service(let error), FetchSessionError.service(let error),
             SignUpError.service(let error):
            return serviceException(in: error)
        case SignInError.webAuthn(.service(let error as Error)):
            return serviceException(in: error)
        case AuthenticationError.service(_, let error?):
            // `ThrowSignInError`: how `USER_AUTH`, auto sign-in and device SRP end a failed call.
            return serviceException(in: error)
        case AuthorizationError.sessionError(let error, _):
            return serviceException(in: error)
        default:
            return failure
        }
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
    init(engineConfirmingSignIn error: EngineAuthError, rejectedByUserPool: Bool, cause: Error? = nil) {
        if rejectedByUserPool, case .notAuthorized(let message, _, _) = error, Self.isInvalidChallengeSession(message) {
            self = .challengeExpired(
                error.errorDescription,
                "The sign-in's challenge can no longer be answered. Call signIn to start a new sign-in.",
                error
            )
        } else {
            self.init(engine: error, cause: cause)
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

extension AuthClientError {

    /// A failed revoke under a sign-out, mapped as `init(engine:cause:)` maps it, except a code-less service failure
    /// whose texts are the client's (`isSignOutContextFailure`), which keeps the sign-out's context: the session is
    /// signed out on this device, and nothing retries the revoke (a second sign-out finds nothing to sign out). A
    /// network failure also says the token may still be valid. `cause` is the failure the engine error was made from
    /// (`EngineRevokeTokenFailure.cause`).
    static func revokeFailure(engine error: EngineAuthError, cause: Error? = nil) -> AuthClientError {
        let mapped = AuthClientError(engine: error, cause: cause)
        guard case .service(nil, let description, let suggestion, let underlying) = mapped,
              isSignOutContextFailure(description: description, suggestion: suggestion) else {
            return mapped
        }
        if description == networkFailureDescription {
            return revokeNetworkFailure(underlying ?? error)
        }
        return .service(nil, description, revokeNotRetriedSuggestion, underlying ?? error)
    }

    /// Whether a code-less service failure under a sign-out takes the sign-out's recovery suggestion: one the client
    /// describes itself (`clientServiceFailureDescriptions`: a transport failure, or one with an empty engine
    /// description), or a failure Cognito reported as its own, whose suggestion is the client's
    /// (`serviceFailureSuggestion(underlying:cause:)`: an internal error, an error status the SDK does not model). Its
    /// "retry the operation" does not fit a sign-out, which already finished on this device.
    static func isSignOutContextFailure(description: String, suggestion: String) -> Bool {
        clientServiceFailureDescriptions.contains(description)
            || [serviceFaultSuggestion, unrecognisedServiceErrorSuggestion].contains(suggestion)
    }

    /// A revoke that failed on the network.
    static func revokeNetworkFailure(_ error: Error) -> AuthClientError {
        .service(nil, revokeNetworkFailureDescription, revokeNotRetriedSuggestion, error)
    }

    static let revokeNetworkFailureDescription =
        "The refresh token may not have been revoked: a network problem stopped the request, which may not have "
            + "reached the service. Unless it did, or a global sign-out succeeded, the refresh token stays valid until "
            + "it expires."
    /// What a failed revoke under a sign-out suggests: the session is signed out on this device, so nothing is left to
    /// retry the revoke with.
    static let revokeNotRetriedSuggestion =
        "The session was signed out on this device, and the revoke will not be retried. To end the refresh token on "
            + "the server, sign in again and sign out with globalSignOut: true."

    /// A failed global sign-out under a sign-out, mapped as `init(engine:cause:)` maps it, except a failure that keeps
    /// the sign-out's context, as a revoke's does (`revokeFailure(engine:cause:)`). One Cognito failed itself (an
    /// internal error, an error status the SDK does not model) reached the service, so its suggestion says the other
    /// sessions stay signed in; one that failed in transport may or may not have, so its suggestion hedges.
    static func globalSignOutFailure(engine error: EngineAuthError, cause: Error? = nil) -> AuthClientError {
        let mapped = AuthClientError(engine: error, cause: cause)
        guard case .service(nil, let description, let suggestion, let underlying) = mapped,
              isSignOutContextFailure(description: description, suggestion: suggestion) else {
            return mapped
        }
        let reachedService = [serviceFaultSuggestion, unrecognisedServiceErrorSuggestion].contains(suggestion)
        return .service(
            nil,
            description,
            reachedService ? globalSignOutFailedNotRetriedSuggestion : globalSignOutNotRetriedSuggestion,
            underlying ?? error
        )
    }

    /// What a global sign-out that failed in transport suggests: the session is signed out on this device, so nothing
    /// is left to retry it with, and the request may or may not have reached the service.
    static let globalSignOutNotRetriedSuggestion =
        "The session was signed out on this device, and the global sign-out will not be retried: unless the request "
            + "reached the service, the user's other sessions stay signed in until their tokens expire. To sign them "
            + "out, sign in again and sign out with globalSignOut: true."

    /// What a global sign-out that Cognito failed itself suggests: the session is signed out on this device, so
    /// nothing is left to retry it with, and the other sessions were not signed out.
    static let globalSignOutFailedNotRetriedSuggestion =
        "The session was signed out on this device, and the global sign-out will not be retried: the user's other "
            + "sessions stay signed in until their tokens expire. To sign them out, sign in again and sign out with "
            + "globalSignOut: true."
}

extension EngineSignOutOutcome {

    /// The sign-out failures, mapped with the errors they were made from: with the sign-out's context, and plainly,
    /// for a sign-out that could not finish (`firstError`). The refresh and access tokens they carry are dropped (not
    /// exposed).
    init(
        revokeFailure: EngineRevokeTokenFailure?,
        globalSignOutFailure: EngineGlobalSignOutFailure?,
        hostedUIFailure: EngineHostedUISignOutFailure? = nil
    ) {
        self.init(
            revokeError: revokeFailure.map { AuthClientError.revokeFailure(engine: $0.error, cause: $0.cause) },
            globalSignOutError: globalSignOutFailure.map {
                AuthClientError.globalSignOutFailure(engine: $0.error, cause: $0.cause)
            },
            hostedUIError: hostedUIFailure.map { AuthClientError(engine: $0.error) },
            plainRevokeError: revokeFailure.map { AuthClientError(engine: $0.error, cause: $0.cause) },
            plainGlobalSignOutError: globalSignOutFailure.map { AuthClientError(engine: $0.error, cause: $0.cause) }
        )
    }
}
