//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The public types for the session operations, the three new `AuthClientError` cases, and
/// their parity with the plugin's types.
///
/// This target cannot import the plugin, so the plugin's case lists and strings are transcribed below,
/// each citing its file and lines in the plugin. The client enums are walked through exhaustive switches with
/// no `default`, so a client-side addition does not compile until the pinned list is revisited, and a
/// plugin-side addition is caught at review against the plugin bridge's mapping table.
final class AuthClientOperationTypesTests: XCTestCase {

    // MARK: - AuthClientError: the three new cases

    /// - Given: one error of each new case
    /// - When: its `AmplifyError` members are read
    /// - Then:
    ///    - it carries its description, suggestion and underlying error, and its code for `.service`
    func testNewErrorCasesCarryTheirPayload() {
        let underlying = FixtureError(description: "engine")
        let service = AuthClientError.service(.codeMismatch, "wrong code", "retry", underlying)
        let notAuthorized = AuthClientError.notAuthorized("bad password", "check it", underlying)
        let invalidState = AuthClientError.invalidState("already signed in", "sign out", underlying)

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

    /// Equality of `AuthSessionState.failed` (and of partial sign-outs) compares the structured payload,
    /// so two service errors that differ only by code must not compare equal.
    ///
    /// - Given: service errors with the same strings and different codes, and the other new cases
    /// - When: they are compared with `isEquivalent(to:)`
    /// - Then:
    ///    - a different code, or a different case, is not equivalent; the same code and strings are
    func testNewErrorCasesCompareByCaseAndCode() {
        let mismatch = AuthClientError.service(.codeMismatch, "d", "s")
        XCTAssertTrue(mismatch.isEquivalent(to: .service(.codeMismatch, "d", "s", FixtureError(description: "other"))))
        XCTAssertFalse(mismatch.isEquivalent(to: .service(.codeExpired, "d", "s")))
        XCTAssertFalse(mismatch.isEquivalent(to: .service(nil, "d", "s")))
        XCTAssertFalse(AuthClientError.notAuthorized("d", "s").isEquivalent(to: .invalidState("d", "s")))
        XCTAssertFalse(AuthClientError.invalidState("d", "s").isEquivalent(to: .unknown("d", "s")))
        XCTAssertNotEqual(AuthSessionState.failed(mismatch), .failed(.service(.userNotFound, "d", "s")))
    }

    /// - Given: one error of each new case: `.service` (with the `.network` code), `.notAuthorized` and
    ///   `.invalidState`
    /// - When: each is converted with `CredentialsError(authClientError:)`
    /// - Then:
    ///    - each converts to the unknown case (`isUnknown`)
    func testNewErrorCasesMapToUnknownForProviders() {
        for error in [
            AuthClientError.service(.network, "d", "s"),
            .notAuthorized("d", "s"),
            .invalidState("d", "s")
        ] {
            XCTAssertTrue(CredentialsError(authClientError: error).isUnknown, "\(error)")
        }
    }

    /// `AmplifyError`'s required initializer.
    ///
    /// - Given: an `AuthClientError` of a specific case, and an error of another type
    /// - When: each is passed to `init(errorDescription:recoverySuggestion:error:)` with other strings, and so is
    ///   no error
    /// - Then:
    ///    - the `AuthClientError` comes back as it is, its case, strings and underlying error kept and the given
    ///      strings ignored
    ///    - the other error, and no error, are wrapped in `.unknown` with the given strings
    func testAmplifyErrorInitializerReturnsAClientErrorOrWrapsInUnknown() {
        let clientError = AuthClientError.service(.codeMismatch, "wrong code", "retry", FixtureError(description: "engine"))
        let returned = AuthClientError(errorDescription: "ignored", recoverySuggestion: "ignored", error: clientError)
        XCTAssertEqual(returned.kind, .service(.codeMismatch))
        XCTAssertEqual(returned.errorDescription, "wrong code")
        XCTAssertEqual(returned.recoverySuggestion, "retry")
        XCTAssertTrue(returned.underlyingError is FixtureError)

        let other = AuthClientError(errorDescription: "d", recoverySuggestion: "s", error: FixtureError(description: "other"))
        guard case .unknown(let description, let suggestion, let underlying) = other else {
            return XCTFail("expected .unknown, got \(other)")
        }
        XCTAssertEqual(description, "d")
        XCTAssertEqual(suggestion, "s")
        XCTAssertTrue(underlying is FixtureError)

        let none = AuthClientError(errorDescription: "d", recoverySuggestion: "s", error: nil)
        guard case .unknown(let description, let suggestion, let underlying) = none else {
            return XCTFail("expected .unknown, got \(none)")
        }
        XCTAssertEqual(description, "d")
        XCTAssertEqual(suggestion, "s")
        XCTAssertNil(underlying)
    }

    // MARK: - AuthClientServiceErrorCode ↔ the plugin's AWSCognitoAuthError

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
    static func name(of code: AuthClientServiceErrorCode) -> String {
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
    /// - When: every `AuthClientServiceErrorCode` is enumerated in declaration order
    /// - Then:
    ///    - the names match the plugin's, in the same order, 34 each
    func testServiceErrorCodeMirrorsThePluginCaseForCase() {
        XCTAssertEqual(AuthClientServiceErrorCode.allCases.map(Self.name(of:)), Self.pluginServiceErrorCases)
        XCTAssertEqual(AuthClientServiceErrorCode.allCases.count, 34)
    }

    /// - Given: a few service codes
    /// - When: their `LocalizedError` descriptions are read
    /// - Then:
    ///    - each has the plugin's message, prefixed with the client's type and case name
    func testServiceErrorCodeCarriesThePluginMessages() {
        XCTAssertEqual(
            AuthClientServiceErrorCode.codeMismatch.errorDescription,
            "AuthClientServiceErrorCode.codeMismatch: Confirmation code entered is not correct."
        )
        XCTAssertEqual(
            AuthClientServiceErrorCode.userNotFound.errorDescription,
            "AuthClientServiceErrorCode.userNotFound: User not found in the system."
        )
        for code in AuthClientServiceErrorCode.allCases {
            XCTAssertTrue(code.errorDescription?.hasPrefix("AuthClientServiceErrorCode.\(Self.name(of: code)): ") == true)
        }
    }

    // MARK: - AuthClientAuthFlowType ↔ the plugin's AuthFlowType

    /// Transcribed from `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Models/AuthFlowType.swift`, lines
    /// 14-34, without the deprecated `custom` (line 19), which has no client case.
    static let pluginFlowTypeCases = ["userSRP", "customWithSRP", "customWithoutSRP", "userPassword", "userAuth"]

    static func name(of flow: AuthClientAuthFlowType) -> String {
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
        let flows: [AuthClientAuthFlowType] = [
            .userSRP, .customWithSRP, .customWithoutSRP, .userPassword, .userAuth(preferredFirstFactor: .emailOTP)
        ]
        XCTAssertEqual(flows.map(Self.name(of:)), Self.pluginFlowTypeCases)
        XCTAssertNotEqual(AuthClientAuthFlowType.userAuth(preferredFirstFactor: nil), .userAuth(preferredFirstFactor: .password))
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
        let expected: [(AuthClientUserAttributeKey, String)] = [
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
        let signIn = AuthClientSignInOptions()
        XCTAssertNil(signIn.authFlowType)
        XCTAssertEqual(signIn.clientMetadata, [:])

        let confirm = AuthClientConfirmSignInOptions()
        XCTAssertEqual(confirm.userAttributes, [])
        XCTAssertEqual(confirm.clientMetadata, [:])
        XCTAssertNil(confirm.friendlyDeviceName)

        XCTAssertEqual(AuthClientSignOutOptions(), AuthClientSignOutOptions(globalSignOut: false, purgeStoredSession: false))
        XCTAssertFalse(AuthClientFetchSessionOptions().forceRefresh)
    }

    /// The design has no `isSignedIn` anywhere in the client's API: a sign-in is complete when its next
    /// step is `.done`, and whether a session is signed in is its state.
    ///
    /// - Given: a sign-in result for each step
    /// - When: they are compared
    /// - Then:
    ///    - each carries its step, and two results are equal exactly when their steps are
    func testSignInResultCarriesItsStep() {
        let steps = AuthClientModelParityTests.clientSignInSteps
        for (index, step) in steps.enumerated() {
            XCTAssertEqual(AuthClientSignInResult(nextStep: step).nextStep, step)
            for (otherIndex, other) in steps.enumerated() {
                XCTAssertEqual(
                    AuthClientSignInResult(nextStep: step) == AuthClientSignInResult(nextStep: other),
                    index == otherIndex,
                    "\(step) vs \(other)"
                )
            }
        }
    }

    /// - Given: sessions that are identical, or that differ only in their identity ID result or their user pool
    ///   tokens result
    /// - When: they are compared with `==`
    /// - Then:
    ///    - identical sessions are equal
    ///    - a different identity ID, or a failure in place of an identity ID, makes them unequal
    ///    - token failures of the same case and strings are equal even when their underlying errors differ, and
    ///      failures of different cases are unequal
    func testSessionEqualityComparesEveryField() {
        let tokens = AuthClientUserPoolTokens(idToken: "i", accessToken: "a", refreshToken: "r")
        let credentials = AuthClientAWSCredentials(accessKeyId: "k", secretAccessKey: "s", sessionToken: "t", expiration: TestClock.start)
        func session(
            identity: Result<String, AuthClientError> = .success("id-1"),
            tokens tokenResult: Result<AuthClientUserPoolTokens, AuthClientError> = .success(tokens)
        ) -> AuthClientSession {
            AuthClientSession(
                identityIdResult: identity,
                awsCredentialsResult: .success(credentials),
                userSubResult: .success("sub"),
                userPoolTokensResult: tokenResult
            )
        }
        XCTAssertEqual(session(), session())
        XCTAssertNotEqual(session(), session(identity: .success("id-2")))
        XCTAssertNotEqual(session(), session(identity: .failure(.notSignedIn("d", "s"))))
        XCTAssertEqual(
            session(tokens: .failure(.sessionExpired("d", "s", FixtureError(description: "a")))),
            session(tokens: .failure(.sessionExpired("d", "s", FixtureError(description: "b"))))
        )
        XCTAssertNotEqual(session(tokens: .failure(.sessionExpired("d", "s"))), session(tokens: .failure(.notSignedIn("d", "s"))))
    }

    /// - Given: user pool tokens and AWS credentials, alone, in a session and in an optional
    /// - When: they are printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - no token or secret appears, and the access key ID appears only masked, as the plugin masks it
    func testTokensAndCredentialsAreRedactedInDebugOutput() {
        let tokens = AuthClientUserPoolTokens(idToken: "ID-SECRET", accessToken: "ACCESS-SECRET", refreshToken: "REFRESH-SECRET")
        let credentials = AuthClientAWSCredentials(CognitoAWSCredentials(
            accessKeyId: "AKID-EXAMPLE",
            secretAccessKey: "SECRET-KEY",
            sessionToken: "SESSION-SECRET",
            expiration: TestClock.start
        ))
        let session = AuthClientSession(
            identityIdResult: .success("id-1"),
            awsCredentialsResult: .success(credentials),
            userSubResult: .success("sub"),
            userPoolTokensResult: .success(tokens)
        )
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
    ///    - a partial sign-out built with only a revoke failure has no global sign-out failure
    func testPartialSignOutComparesBothFailures() {
        let revoke = AuthClientError.service(.network, "revoke failed", "retry")
        let global = AuthClientError.notAuthorized("global failed", "sign in again")
        XCTAssertEqual(
            AuthClientPartialSignOut(revokeError: revoke, globalSignOutError: global),
            AuthClientPartialSignOut(revokeError: revoke, globalSignOutError: global)
        )
        XCTAssertNotEqual(
            AuthClientPartialSignOut(revokeError: nil, globalSignOutError: global),
            AuthClientPartialSignOut(revokeError: revoke, globalSignOutError: global)
        )
        XCTAssertNotEqual(
            AuthClientPartialSignOut(revokeError: revoke, globalSignOutError: nil),
            AuthClientPartialSignOut(revokeError: revoke, globalSignOutError: global)
        )
        XCTAssertNil(AuthClientPartialSignOut(revokeError: revoke).globalSignOutError)
    }

    /// - Given: engine sign-out outcomes across several attempts
    /// - When: they are merged
    /// - Then:
    ///    - the first failure of each kind is kept; a complete outcome has no partial result
    func testSignOutOutcomeKeepsTheFirstFailureOfEachKind() {
        let first = AuthClientError.service(.network, "first", "s")
        let second = AuthClientError.service(.network, "second", "s")
        let global = AuthClientError.unknown("global", "s")

        var outcome = EngineSignOutOutcome.complete
        XCTAssertNil(outcome.partial)
        outcome.merge(EngineSignOutOutcome(revokeError: first))
        outcome.merge(EngineSignOutOutcome(revokeError: second, globalSignOutError: global))

        XCTAssertEqual(outcome, EngineSignOutOutcome(revokeError: first, globalSignOutError: global))
        XCTAssertEqual(outcome.partial, AuthClientPartialSignOut(revokeError: first, globalSignOutError: global))
    }
}
