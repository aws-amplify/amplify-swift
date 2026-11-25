//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The public types for the session operations, the three new `AmplifyCognitoClientError` cases, and
/// their parity with the plugin's types.
///
/// This target cannot import the plugin, so the plugin's case lists and strings are transcribed below,
/// each citing its file and lines in the plugin. The client enums are
/// walked through exhaustive switches with no `default`, so a client-side addition does not compile until
/// the pinned list is revisited, and a case added to Amplify core (or the plugin) is only caught at review;
/// the plugin bridge, when it ships, will map them.
final class AmplifyCognitoClientOperationTypesTests: XCTestCase {

    // MARK: - AmplifyCognitoClientError: the three new cases

    /// - Given: one error of each new case
    /// - When: its `AmplifyError` members are read
    /// - Then:
    ///    - it carries its description, suggestion and underlying error, and its code for `.service`
    func testNewErrorCasesCarryTheirPayload() {
        let underlying = FixtureError(description: "engine")
        let service = AmplifyCognitoClientError.service(.codeMismatch, "wrong code", "retry", underlying)
        let notAuthorized = AmplifyCognitoClientError.notAuthorized("bad password", "check it", underlying)
        let invalidState = AmplifyCognitoClientError.invalidState("already signed in", "sign out", underlying)

        for (error, description, suggestion) in [
            (service, "wrong code", "retry"),
            (notAuthorized, "bad password", "check it"),
            (invalidState, "already signed in", "sign out")
        ] {
            XCTAssertEqual(error.errorDescription, description)
            XCTAssertEqual(error.recoverySuggestion, suggestion)
            XCTAssertTrue(error.underlyingError is FixtureError)
        }
        guard case .service(let code, _, _, _) = service else {
            return XCTFail("\(service)")
        }
        XCTAssertEqual(code, .codeMismatch)
    }

    /// Equality of `AmplifyCognitoClientSessionState.failed` (and of partial sign-outs) compares the structured payload,
    /// so two service errors that differ only by code must not compare equal.
    ///
    /// - Given: service errors with the same strings and different codes, and the other new cases
    /// - When: they are compared with `isEquivalent(to:)`
    /// - Then:
    ///    - a different code, or a different case, is not equivalent; the same code and strings are
    func testNewErrorCasesCompareByCaseAndCode() {
        let mismatch = AmplifyCognitoClientError.service(.codeMismatch, "d", "s")
        XCTAssertTrue(mismatch.isEquivalent(to: .service(.codeMismatch, "d", "s", FixtureError(description: "other"))))
        XCTAssertFalse(mismatch.isEquivalent(to: .service(.codeExpired, "d", "s")))
        XCTAssertFalse(mismatch.isEquivalent(to: .service(nil, "d", "s")))
        XCTAssertFalse(AmplifyCognitoClientError.notAuthorized("d", "s").isEquivalent(to: .invalidState("d", "s")))
        XCTAssertFalse(AmplifyCognitoClientError.invalidState("d", "s").isEquivalent(to: .unknown("d", "s")))
        XCTAssertNotEqual(AmplifyCognitoClientSessionState.failed(mismatch), .failed(.service(.userNotFound, "d", "s")))
    }

    /// - Given: one error of each new case: `.service` (with the `.network` code), `.notAuthorized` and
    ///   `.invalidState`
    /// - When: each is converted with `CredentialsError(authClientError:)`
    /// - Then:
    ///    - each converts to the unknown case (`isUnknown`)
    func testNewErrorCasesMapToUnknownForProviders() {
        for error in [
            AmplifyCognitoClientError.service(.network, "d", "s"),
            .notAuthorized("d", "s"),
            .invalidState("d", "s")
        ] {
            XCTAssertTrue(CredentialsError(authClientError: error).isUnknown, "\(error)")
        }
    }

    /// `AmplifyError`'s required initializer.
    ///
    /// - Given: an `AmplifyCognitoClientError` of a specific case, and an error of another type
    /// - When: each is passed to `init(errorDescription:recoverySuggestion:error:)` with other strings, and so is
    ///   no error
    /// - Then:
    ///    - the `AmplifyCognitoClientError` comes back as it is, its case, strings and underlying error kept and the given
    ///      strings ignored
    ///    - the other error, and no error, are wrapped in `.unknown` with the given strings
    func testAmplifyErrorInitializerReturnsAClientErrorOrWrapsInUnknown() {
        let clientError = AmplifyCognitoClientError.service(.codeMismatch, "wrong code", "retry", FixtureError(description: "engine"))
        let returned = AmplifyCognitoClientError(errorDescription: "ignored", recoverySuggestion: "ignored", error: clientError)
        XCTAssertEqual(returned.kind, .service(.codeMismatch))
        XCTAssertEqual(returned.errorDescription, "wrong code")
        XCTAssertEqual(returned.recoverySuggestion, "retry")
        XCTAssertTrue(returned.underlyingError is FixtureError)

        let other = AmplifyCognitoClientError(errorDescription: "d", recoverySuggestion: "s", error: FixtureError(description: "other"))
        guard case .unknown(let description, let suggestion, let underlying) = other else {
            return XCTFail("expected .unknown, got \(other)")
        }
        XCTAssertEqual(description, "d")
        XCTAssertEqual(suggestion, "s")
        XCTAssertTrue(underlying is FixtureError)

        let none = AmplifyCognitoClientError(errorDescription: "d", recoverySuggestion: "s", error: nil)
        guard case .unknown(let description, let suggestion, let underlying) = none else {
            return XCTFail("expected .unknown, got \(none)")
        }
        XCTAssertEqual(description, "d")
        XCTAssertEqual(suggestion, "s")
        XCTAssertNil(underlying)
    }

    // MARK: - AmplifyCognitoClientServiceErrorCode ↔ the plugin's AWSCognitoAuthError

    /// Transcribed from `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Models/Errors/AWSCognitoAuthError.swift`,
    /// lines 13-113.
    static let pluginServiceErrorCases = [
        "userNotFound", "userNotConfirmed", "usernameExists", "aliasExists", "codeDelivery", "codeMismatch",
        "codeExpired", "invalidParameter", "invalidPassword", "limitExceeded", "mfaMethodNotFound",
        "softwareTokenMFANotEnabled", "passwordResetRequired", "resourceNotFound", "failedAttemptsLimitExceeded",
        "requestLimitExceeded", "lambda", "deviceNotTracked", "errorLoadingUI", "userCancelled",
        "invalidAccountTypeException", "network", "smsRole", "emailRole", "externalServiceException",
        "limitExceededException", "resourceConflictException", "webAuthnChallengeNotFound",
        "webAuthnClientMismatch", "webAuthnNotSupported", "webAuthnNotEnabled", "webAuthnOriginNotAllowed",
        "webAuthnRelyingPartyMismatch", "webAuthnConfigurationMissing"
    ]

    /// Exhaustive on purpose: no `default`.
    static func name(of code: AmplifyCognitoClientServiceErrorCode) -> String {
        switch code {
        case .userNotFound: return "userNotFound"
        case .userNotConfirmed: return "userNotConfirmed"
        case .usernameExists: return "usernameExists"
        case .aliasExists: return "aliasExists"
        case .codeDelivery: return "codeDelivery"
        case .codeMismatch: return "codeMismatch"
        case .codeExpired: return "codeExpired"
        case .invalidParameter: return "invalidParameter"
        case .invalidPassword: return "invalidPassword"
        case .limitExceeded: return "limitExceeded"
        case .mfaMethodNotFound: return "mfaMethodNotFound"
        case .softwareTokenMFANotEnabled: return "softwareTokenMFANotEnabled"
        case .passwordResetRequired: return "passwordResetRequired"
        case .resourceNotFound: return "resourceNotFound"
        case .failedAttemptsLimitExceeded: return "failedAttemptsLimitExceeded"
        case .requestLimitExceeded: return "requestLimitExceeded"
        case .lambda: return "lambda"
        case .deviceNotTracked: return "deviceNotTracked"
        case .errorLoadingUI: return "errorLoadingUI"
        case .userCancelled: return "userCancelled"
        case .invalidAccountTypeException: return "invalidAccountTypeException"
        case .network: return "network"
        case .smsRole: return "smsRole"
        case .emailRole: return "emailRole"
        case .externalServiceException: return "externalServiceException"
        case .limitExceededException: return "limitExceededException"
        case .resourceConflictException: return "resourceConflictException"
        case .webAuthnChallengeNotFound: return "webAuthnChallengeNotFound"
        case .webAuthnClientMismatch: return "webAuthnClientMismatch"
        case .webAuthnNotSupported: return "webAuthnNotSupported"
        case .webAuthnNotEnabled: return "webAuthnNotEnabled"
        case .webAuthnOriginNotAllowed: return "webAuthnOriginNotAllowed"
        case .webAuthnRelyingPartyMismatch: return "webAuthnRelyingPartyMismatch"
        case .webAuthnConfigurationMissing: return "webAuthnConfigurationMissing"
        }
    }

    /// - Given: the plugin's `AWSCognitoAuthError` case list
    /// - When: every `AmplifyCognitoClientServiceErrorCode` is enumerated in declaration order
    /// - Then:
    ///    - the names match the plugin's, in the same order, 34 each
    func testServiceErrorCodeMirrorsThePluginCaseForCase() {
        XCTAssertEqual(AmplifyCognitoClientServiceErrorCode.allCases.map(Self.name(of:)), Self.pluginServiceErrorCases)
        XCTAssertEqual(AmplifyCognitoClientServiceErrorCode.allCases.count, 34)
    }

    /// - Given: a few service codes
    /// - When: their `errorDescription`s are read
    /// - Then:
    ///    - each has the plugin's message, prefixed with the client's type and case name
    func testServiceErrorCodeCarriesThePluginMessages() {
        XCTAssertEqual(
            AmplifyCognitoClientServiceErrorCode.codeMismatch.errorDescription,
            "AmplifyCognitoClientServiceErrorCode.codeMismatch: Confirmation code entered is not correct."
        )
        XCTAssertEqual(
            AmplifyCognitoClientServiceErrorCode.userNotFound.errorDescription,
            "AmplifyCognitoClientServiceErrorCode.userNotFound: User not found in the system."
        )
        for code in AmplifyCognitoClientServiceErrorCode.allCases {
            XCTAssertTrue(code.errorDescription?.hasPrefix("AmplifyCognitoClientServiceErrorCode.\(Self.name(of: code)): ") == true)
        }
    }

    /// - Given: a service code
    /// - When: it is checked for `Error` conformance at run time
    /// - Then:
    ///    - it is not an `Error`: the code is a plain value, carried by `AmplifyCognitoClientError.service` and never
    ///      thrown on its own
    func testServiceErrorCodeIsNotAnError() {
        XCTAssertFalse((AmplifyCognitoClientServiceErrorCode.userNotFound as Any) is Error)
        for code in AmplifyCognitoClientServiceErrorCode.allCases {
            XCTAssertFalse((code as Any) is Error, "\(code)")
        }
    }

    /// The plugin's message for each case, as it was while the type was a `LocalizedError`.
    static let pinnedServiceErrorMessages: [(AmplifyCognitoClientServiceErrorCode, String)] = [
        (.userNotFound, "User not found in the system."),
        (.userNotConfirmed, "User not confirmed in the system."),
        (.usernameExists, "Username already exists in the system."),
        (.aliasExists, "Alias already exists in the system."),
        (.codeDelivery, "Error in delivering the confirmation code."),
        (.codeMismatch, "Confirmation code entered is not correct."),
        (.codeExpired, "Confirmation code has expired."),
        (.invalidParameter, "One or more parameters are incorrect."),
        (.invalidPassword, "Password given is invalid."),
        (.limitExceeded, "Limit exceeded for the requested AWS resource."),
        (.mfaMethodNotFound, "Amazon Cognito cannot find a multi-factor authentication (MFA) method."),
        (.softwareTokenMFANotEnabled, "Software token (TOTP) multi-factor authentication (MFA) is not enabled for the user pool."),
        (.passwordResetRequired, "Required to reset the password of the user."),
        (.resourceNotFound, "Amazon Cognito service cannot find the requested resource."),
        (.failedAttemptsLimitExceeded, "The user has made too many failed attempts for a given action."),
        (.requestLimitExceeded, "The user has made too many requests for a given operation."),
        (.lambda, "Amazon Cognito service encountered an invalid AWS Lambda response or encountered an unexpected exception with the AWS Lambda service."),
        (.deviceNotTracked, "Device is not tracked."),
        (.errorLoadingUI, "Error in loading the web UI."),
        (.userCancelled, "User cancelled the step."),
        (.invalidAccountTypeException, "Requested resource is not available with the current account setup."),
        (.network, "Request was not completed because of a network related issue."),
        (.smsRole, "SMS role related issue."),
        (.emailRole, "Email role related issue."),
        (.externalServiceException, "An external service like facebook/twitter threw an error."),
        (.limitExceededException, "Limit exceeded exception. Thrown when the total number of user pools has exceeded a preset limit."),
        (.resourceConflictException, "Thrown when a user tries to use a login which is already linked to another account."),
        (.webAuthnChallengeNotFound, "The WebAuthn credentials don't match an existing request."),
        (.webAuthnClientMismatch, "The client doesn't support WebAuhn authentication."),
        (.webAuthnNotSupported, "WebAuthn is not supported on this device."),
        (.webAuthnNotEnabled, "WebAuthn is not enabled."),
        (.webAuthnOriginNotAllowed, "The device origin is not registered as an allowed origin."),
        (.webAuthnRelyingPartyMismatch, "The relying party ID doesn't match."),
        (.webAuthnConfigurationMissing, "The WebAuthn configuration is missing or incomplete.")
    ]

    /// - Given: the message each of the 34 service codes carried while the type was a `LocalizedError`
    /// - When: each code's plain `errorDescription` property is read
    /// - Then:
    ///    - the text is unchanged apart from the type's name:
    ///      `"AmplifyCognitoClientServiceErrorCode.<case>: <the plugin's message>"`, for every case
    func testErrorDescriptionIsUnchanged() {
        XCTAssertEqual(Self.pinnedServiceErrorMessages.count, AmplifyCognitoClientServiceErrorCode.allCases.count)
        XCTAssertEqual(Self.pinnedServiceErrorMessages.map(\.0), AmplifyCognitoClientServiceErrorCode.allCases)
        for (code, message) in Self.pinnedServiceErrorMessages {
            XCTAssertEqual(code.errorDescription, "AmplifyCognitoClientServiceErrorCode.\(Self.name(of: code)): \(message)")
        }
    }

    // MARK: - AmplifyCognitoClientAuthFlowType ↔ the plugin's AuthFlowType

    /// Transcribed from `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Models/AuthFlowType.swift`, lines
    /// 14-34, without the deprecated `custom` (line 19), which has no client case.
    static let pluginFlowTypeCases = ["userSRP", "customWithSRP", "customWithoutSRP", "userPassword", "userAuth"]

    static func name(of flow: AmplifyCognitoClientAuthFlowType) -> String {
        switch flow {
        case .userSRP: return "userSRP"
        case .customWithSRP: return "customWithSRP"
        case .customWithoutSRP: return "customWithoutSRP"
        case .userPassword: return "userPassword"
        case .userAuth: return "userAuth"
        }
    }

    /// - Given: the plugin's `AuthFlowType` cases, less the deprecated `custom`
    /// - When: one value of each client case is named
    /// - Then:
    ///    - the names match, and `userAuth` carries its preferred first factor
    func testAuthFlowTypeMirrorsThePluginWithoutTheDeprecatedCase() {
        let flows: [AmplifyCognitoClientAuthFlowType] = [
            .userSRP, .customWithSRP, .customWithoutSRP, .userPassword, .userAuth(preferredFirstFactor: .emailOTP)
        ]
        XCTAssertEqual(flows.map(Self.name(of:)), Self.pluginFlowTypeCases)
        XCTAssertNotEqual(AmplifyCognitoClientAuthFlowType.userAuth(preferredFirstFactor: nil), .userAuth(preferredFirstFactor: .password))
    }

    // MARK: - Attribute keys → Cognito names

    /// Transcribed from `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Support/Utils/AuthUserAttributeKey+RawValue.swift`,
    /// lines 18-38 and 118-120.
    ///
    /// - Given: the plugin's Cognito name for each of the 20 standard attribute keys, plus one `.custom` and one
    ///   `.unknown` key
    /// - When: each client key's `cognitoName` is read
    /// - Then:
    ///    - every name matches the plugin's: `.custom` gains the `custom:` prefix, and `.unknown` passes its
    ///      name through unchanged
    func testAttributeKeysMapToThePluginsCognitoNames() {
        let expected: [(AmplifyCognitoClientUserAttributeKey, String)] = [
            (.address, "address"), (.birthDate, "birthdate"), (.email, "email"), (.emailVerified, "email_verified"),
            (.familyName, "family_name"), (.gender, "gender"), (.givenName, "given_name"), (.locale, "locale"),
            (.middleName, "middle_name"), (.name, "name"), (.nickname, "nickname"), (.phoneNumber, "phone_number"),
            (.phoneNumberVerified, "phone_number_verified"), (.picture, "picture"),
            (.preferredUsername, "preferred_username"), (.profile, "profile"), (.sub, "sub"),
            (.updatedAt, "updated_at"), (.website, "website"), (.zoneInfo, "zoneinfo"),
            (.custom("team"), "custom:team"), (.unknown("dev:flag"), "dev:flag")
        ]
        XCTAssertEqual(expected.count, 22)
        for (key, name) in expected {
            XCTAssertEqual(key.cognitoName, name, "\(key)")
        }
    }

    // MARK: - Options and results

    /// - Given: every option type built with no arguments
    /// - When: its fields are read
    /// - Then:
    ///    - the defaults are the plugin's: no flow override, no metadata, no attributes, no device name,
    ///      not global, no purge, no forced refresh
    func testOptionDefaultsMatchThePlugin() {
        let signIn = AmplifyCognitoClientSignInOptions()
        XCTAssertNil(signIn.authFlowType)
        XCTAssertEqual(signIn.clientMetadata, [:])

        let confirm = AmplifyCognitoClientConfirmSignInOptions()
        XCTAssertEqual(confirm.userAttributes, [])
        XCTAssertEqual(confirm.clientMetadata, [:])
        XCTAssertNil(confirm.friendlyDeviceName)

        XCTAssertEqual(AmplifyCognitoClientSignOutOptions(), AmplifyCognitoClientSignOutOptions(globalSignOut: false, purgeStoredSession: false))
        XCTAssertFalse(AmplifyCognitoClientFetchAuthSessionOptions().forceRefresh)
    }

    /// The design has no `isSignedIn` anywhere in the client's API: a sign-in is complete when its next
    /// step is `.done`, and whether a session is signed in is its state.
    ///
    /// - Given: a sign-in result for each step
    /// - When: they are compared
    /// - Then:
    ///    - each carries its step, and two results are equal exactly when their steps are
    func testSignInResultCarriesItsStep() {
        let steps = AmplifyCognitoClientModelParityTests.clientSignInSteps
        for (index, step) in steps.enumerated() {
            XCTAssertEqual(AmplifyCognitoClientSignInResult(nextStep: step).nextStep, step)
            for (otherIndex, other) in steps.enumerated() {
                XCTAssertEqual(
                    AmplifyCognitoClientSignInResult(nextStep: step) == AmplifyCognitoClientSignInResult(nextStep: other),
                    index == otherIndex,
                    "\(step) vs \(other)"
                )
            }
        }
    }

    /// - Given: sessions that are identical, or that differ only in their identity ID or their user pool tokens
    /// - When: they are compared with `==`
    /// - Then:
    ///    - identical sessions are equal, and so are two with no fields
    ///    - a different identity ID, no identity ID, other tokens or no tokens makes them unequal
    func testSessionEqualityComparesEveryField() {
        let tokens = AmplifyCognitoClientUserPoolTokens(idToken: "i", accessToken: "a", refreshToken: "r")
        let credentials = AmplifyCognitoClientAWSCredentials(accessKeyId: "k", secretAccessKey: "s", sessionToken: "t", expiration: TestClock.start)
        func session(identity: String? = "id-1", tokens sessionTokens: AmplifyCognitoClientUserPoolTokens? = tokens) -> AmplifyCognitoClientAuthSession {
            AmplifyCognitoClientAuthSession(identityId: identity, awsCredentials: credentials, userSub: "sub", userPoolTokens: sessionTokens)
        }
        XCTAssertEqual(session(), session())
        XCTAssertEqual(AmplifyCognitoClientAuthSession(), AmplifyCognitoClientAuthSession())
        XCTAssertNotEqual(session(), session(identity: "id-2"))
        XCTAssertNotEqual(session(), session(identity: nil))
        XCTAssertNotEqual(session(), session(tokens: AmplifyCognitoClientUserPoolTokens(idToken: "i", accessToken: "other", refreshToken: "r")))
        XCTAssertNotEqual(session(), session(tokens: nil))
        XCTAssertNotEqual(session(), AmplifyCognitoClientAuthSession())
    }

    /// - Given: user pool tokens and AWS credentials, alone, in a session and in an optional
    /// - When: they are printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - no token or secret appears, and the access key ID appears only masked, as the plugin masks it
    func testTokensAndCredentialsAreRedactedInDebugOutput() {
        let tokens = AmplifyCognitoClientUserPoolTokens(idToken: "ID-SECRET", accessToken: "ACCESS-SECRET", refreshToken: "REFRESH-SECRET")
        let credentials = AmplifyCognitoClientAWSCredentials(CognitoAWSCredentials(
            accessKeyId: "AKID-EXAMPLE",
            secretAccessKey: "SECRET-KEY",
            sessionToken: "SESSION-SECRET",
            expiration: TestClock.start
        ))
        let session = AmplifyCognitoClientAuthSession(identityId: "id-1", awsCredentials: credentials, userSub: "sub", userPoolTokens: tokens)
        for value in [tokens, credentials, session, Optional(tokens) as Any] as [Any] {
            var dumped = ""
            dump(value, to: &dumped)
            let output = [String(describing: value), String(reflecting: value), "\(value)", dumped].joined(separator: "\n")
            for secret in ["ID-SECRET", "ACCESS-SECRET", "REFRESH-SECRET", "SECRET-KEY", "SESSION-SECRET", "AKID-EXAMPLE"] {
                XCTAssertFalse(output.contains(secret), "\(secret) in \(output)")
            }
        }
        XCTAssertTrue(String(describing: credentials).contains("accessKeyId: AK*****LE"), String(describing: credentials))
        XCTAssertEqual(Mirror(reflecting: credentials).children.map(\.label), ["accessKeyId", "secretAccessKey", "sessionToken", "expiration"])
        XCTAssertEqual(Mirror(reflecting: tokens).children.map(\.label), ["idToken", "accessToken", "refreshToken"])
        XCTAssertEqual(credentials.sessionToken, "SESSION-SECRET")
        let asFoundation: AWSTemporaryCredentials = credentials
        XCTAssertEqual(asFoundation.expiration, TestClock.start)
    }

    // MARK: - Partial sign-out

    /// - Given: partial sign-outs with the same revoke and global sign-out failures, and ones where one of the two
    ///   failures is missing
    /// - When: they are compared with `==`
    /// - Then:
    ///    - the same two failures are equal
    ///    - a missing revoke failure, or a missing global sign-out failure, makes them unequal
    ///    - a missing or extra storage failure makes them unequal
    func testPartialSignOutComparesBothFailures() {
        let revoke = AmplifyCognitoClientError.service(.network, "revoke failed", "retry")
        let global = AmplifyCognitoClientError.notAuthorized("global failed", "sign in again")
        let storage = AmplifyCognitoClientError.storageUnavailable(.interrupted, "row kept", "purge")
        XCTAssertEqual(
            AmplifyCognitoClientSignOutResult.partialResult(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: nil, storageError: nil),
            .partialResult(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: nil, storageError: nil)
        )
        XCTAssertNotEqual(
            AmplifyCognitoClientSignOutResult.partialResult(revokeTokenError: nil, globalSignOutError: global, hostedUIError: nil, storageError: nil),
            .partialResult(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: nil, storageError: nil)
        )
        XCTAssertNotEqual(
            AmplifyCognitoClientSignOutResult.partialResult(revokeTokenError: revoke, globalSignOutError: nil, hostedUIError: nil, storageError: nil),
            .partialResult(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: nil, storageError: nil)
        )
        XCTAssertNotEqual(
            AmplifyCognitoClientSignOutResult.partialResult(revokeTokenError: revoke, globalSignOutError: nil, hostedUIError: nil, storageError: storage),
            .partialResult(revokeTokenError: revoke, globalSignOutError: nil, hostedUIError: nil, storageError: nil)
        )
    }

    /// - Given: an engine sign-out outcome with a revoke, a global sign-out and a hosted-UI failure
    /// - When: its public result is built
    /// - Then:
    ///    - each `.partial` wrapper carries the outcome's own error, one `.error` step down
    ///    - a wrapper compares as its error does: another error is unequal, and the underlying error takes no part
    func testEachPartialWrapperCarriesItsError() {
        let revoke = AmplifyCognitoClientError.service(.network, "revoke failed", "retry")
        let global = AmplifyCognitoClientError.notAuthorized("global failed", "sign in again")
        let hostedUI = AmplifyCognitoClientError.userCancelled("closed", "retry")
        let outcome = EngineSignOutOutcome(revokeError: revoke, globalSignOutError: global, hostedUIError: hostedUI)

        guard case .partial(let revokeTokenError, let globalSignOutError, let hostedUIError, let storageError)
            = outcome.signedOutResult() else {
            return XCTFail("expected .partial, got \(outcome.signedOutResult())")
        }
        XCTAssertEqual(revokeTokenError, AmplifyCognitoClientRevokeTokenError(error: revoke))
        XCTAssertEqual(globalSignOutError, AmplifyCognitoClientGlobalSignOutError(error: global))
        XCTAssertEqual(hostedUIError, AmplifyCognitoClientHostedUIError(error: hostedUI))
        XCTAssertNil(storageError)
        XCTAssertNotEqual(revokeTokenError, AmplifyCognitoClientRevokeTokenError(error: global))
        XCTAssertNotEqual(globalSignOutError, AmplifyCognitoClientGlobalSignOutError(error: revoke))
        XCTAssertNotEqual(hostedUIError, AmplifyCognitoClientHostedUIError(error: revoke))
        let first = AmplifyCognitoClientError.service(.network, "revoke failed", "retry", FixtureError(description: "a"))
        let second = AmplifyCognitoClientError.service(.network, "revoke failed", "retry", FixtureError(description: "b"))
        XCTAssertEqual(AmplifyCognitoClientRevokeTokenError(error: first), AmplifyCognitoClientRevokeTokenError(error: second))
        XCTAssertEqual(AmplifyCognitoClientGlobalSignOutError(error: first), AmplifyCognitoClientGlobalSignOutError(error: second))
        XCTAssertEqual(AmplifyCognitoClientHostedUIError(error: first), AmplifyCognitoClientHostedUIError(error: second))
    }

    /// - Given: engine sign-out outcomes across several attempts
    /// - When: they are merged
    /// - Then:
    ///    - the first failure of each kind is kept; a complete outcome is a `.complete` result
    func testSignOutOutcomeKeepsTheFirstFailureOfEachKind() {
        let first = AmplifyCognitoClientError.service(.network, "first", "s")
        let second = AmplifyCognitoClientError.service(.network, "second", "s")
        let global = AmplifyCognitoClientError.unknown("global", "s")

        var outcome = EngineSignOutOutcome.complete
        XCTAssertEqual(outcome.signedOutResult(), .complete)
        outcome.merge(EngineSignOutOutcome(revokeError: first))
        outcome.merge(EngineSignOutOutcome(revokeError: second, globalSignOutError: global))

        XCTAssertEqual(outcome, EngineSignOutOutcome(revokeError: first, globalSignOutError: global))
        XCTAssertEqual(
            outcome.signedOutResult(),
            .partialResult(revokeTokenError: first, globalSignOutError: global, hostedUIError: nil, storageError: nil)
        )
    }
}
