//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The engine -> client mappers, directly, case for case, rather than only transitively (engine <-> plugin by
/// the plugin's goldens, plugin <-> client by the model parity tests).
///
/// Every table has one row per engine case. The `…CaseIndex` helpers are exhaustive switches with no
/// `default:`, so a new engine case does not compile here until it has a row, and each test checks that its
/// rows cover every index.
final class EngineMappingTests: XCTestCase {

    private static let details = EngineCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: "phone_number")
    private static let clientDetails = AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: .phoneNumber)
    private static let info = ["key": "value"]

    // MARK: Sign-in steps

    /// Test that every engine sign-in step maps to the client step of the same name and payload
    ///
    /// - Given: one engine step per case, in `track-I-model-parity.md` line order, with every payload filled
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - it is the client case of the same name, with the payload mapped element by element; the rows cover
    ///      all 14 cases
    ///
    func testEverySignInStepMapsCaseForCase() {
        let rows: [(EngineSignInStep, AuthClientSignInStep)] = [
            (.confirmSignInWithSMSMFACode(Self.details, Self.info), .confirmSignInWithSMSMFACode(Self.clientDetails, Self.info)),
            (.confirmSignInWithSMSMFACode(Self.details, nil), .confirmSignInWithSMSMFACode(Self.clientDetails, nil)),
            (.confirmSignInWithCustomChallenge(Self.info), .confirmSignInWithCustomChallenge(Self.info)),
            (.confirmSignInWithNewPassword(nil), .confirmSignInWithNewPassword(nil)),
            (.confirmSignInWithPassword, .confirmSignInWithPassword),
            (.confirmSignInWithTOTPCode, .confirmSignInWithTOTPCode),
            (
                .continueSignInWithTOTPSetup(EngineTOTPSetupDetails(sharedSecret: "secret", username: "alice")),
                .continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(sharedSecret: "secret", username: "alice"))
            ),
            (.continueSignInWithMFASelection([.sms, .totp, .email]), .continueSignInWithMFASelection([.sms, .totp, .email])),
            (.continueSignInWithEmailMFASetup, .continueSignInWithEmailMFASetup),
            (.continueSignInWithMFASetupSelection([.totp, .email]), .continueSignInWithMFASetupSelection([.totp, .email])),
            (.confirmSignInWithOTP(Self.details), .confirmSignInWithOTP(Self.clientDetails)),
            (
                .continueSignInWithFirstFactorSelection([.password, .passwordSRP, .smsOTP, .emailOTP]),
                .continueSignInWithFirstFactorSelection([.password, .passwordSRP, .smsOTP, .emailOTP])
            ),
            (.resetPassword(Self.info), .resetPassword(Self.info)),
            (.confirmSignUp(nil), .confirmSignUp(nil)),
            (.done, .done)
        ]

        for (engine, client) in rows {
            XCTAssertEqual(AuthClientSignInStep(engine), client, "\(engine)")
            XCTAssertEqual(Self.signInStepCaseIndex(engine), Self.signInStepCaseIndex(client), "\(engine)")
        }
        XCTAssertEqual(Set(rows.map { Self.signInStepCaseIndex($0.0) }), Set(0 ..< 14))
    }

    /// Test that the first-factor selection keeps WebAuthn where the platform has it
    ///
    /// - Given: an engine first-factor selection that includes WebAuthn, where the case is available
    /// - When:
    ///    - it is mapped
    /// - Then:
    ///    - the client selection includes WebAuthn too
    ///
    func testFirstFactorSelectionKeepsWebAuthn() throws {
        #if os(iOS) || os(macOS) || os(visionOS)
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        XCTAssertEqual(
            AuthClientSignInStep(.continueSignInWithFirstFactorSelection([.webAuthn, .password])),
            .continueSignInWithFirstFactorSelection([.webAuthn, .password])
        )
        #else
        throw XCTSkip("WebAuthn is not available on this platform")
        #endif
    }

    // MARK: Payload types

    /// Test that MFA types map case to case, not through their raw values, which differ
    ///
    /// - Given: every engine MFA type
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - it is the client case of the same name, although the engine's raw value is the Cognito string and
    ///      the client's is the public name
    ///    - the client case's `challengeResponse` is the engine's, which the engine answers selections with
    ///
    func testMFATypesMapCaseToCaseNotByRawValue() {
        let rows: [(EngineMFAType, AuthClientMFAType, String)] = [
            (.sms, .sms, "SMS_MFA"),
            (.totp, .totp, "SOFTWARE_TOKEN_MFA"),
            (.email, .email, "EMAIL_OTP")
        ]
        for (engine, client, cognitoName) in rows {
            XCTAssertEqual(AuthClientMFAType(engine), client)
            XCTAssertEqual(engine.rawValue, cognitoName)
            XCTAssertNotEqual(engine.rawValue, client.rawValue)
            XCTAssertEqual(client.challengeResponse, engine.challengeResponse)
        }
        XCTAssertEqual(Set(rows.map { Self.mfaCaseIndex($0.0) }), Set(0 ..< 3))
    }

    /// Test that factor types map case to case in both directions
    ///
    /// - Given: every factor type available on this platform
    /// - When:
    ///    - each engine factor is mapped to the client, and each client factor to the engine
    /// - Then:
    ///    - both directions pair the same names, and the round trip is the identity
    ///
    func testFactorTypesMapCaseToCaseBothWays() {
        var rows: [(EngineAuthFactorType, AuthClientFactorType)] = [
            (.password, .password), (.passwordSRP, .passwordSRP), (.smsOTP, .smsOTP), (.emailOTP, .emailOTP)
        ]
        var expectedCases = 4
        #if os(iOS) || os(macOS) || os(visionOS)
        expectedCases = 5
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            rows.append((.webAuthn, .webAuthn))
        } else {
            expectedCases = 4
        }
        #endif
        for (engine, client) in rows {
            XCTAssertEqual(AuthClientFactorType(engine), client)
            XCTAssertEqual(EngineAuthFactorType(client), engine)
            XCTAssertEqual(AuthClientFactorType(EngineAuthFactorType(client)), client)
            XCTAssertNotEqual(engine.rawValue, client.rawValue)
        }
        XCTAssertEqual(Set(rows.map { Self.factorCaseIndex($0.0) }).count, expectedCases)
    }

    /// Test that a factor's challenge response is Cognito's name for it, which a factor selection accepts
    ///
    /// - Given: every factor type available on this platform
    /// - When:
    ///    - its `challengeResponse` is read, and checked as the answer to a first-factor selection
    /// - Then:
    ///    - it is the engine's (and so the plugin's) challenge response for the same factor, and it parses
    ///      back to that factor
    ///    - the core's selection check passes it for every factor, WebAuthn included: whether a `WEB_AUTHN`
    ///      answer has a window is the engine's check (`ChallengeTests`,
    ///      `testWebAuthnWithoutAPresentationAnchorIsRefused`)
    ///
    func testFactorChallengeResponsesAreCognitosNamesAndPassTheSelectionCheck() throws {
        var factors: [AuthClientFactorType] = [.password, .passwordSRP, .smsOTP, .emailOTP]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            factors.append(.webAuthn)
        }
        #endif
        XCTAssertEqual(
            factors.prefix(4).map(\.challengeResponse),
            ["PASSWORD", "PASSWORD_SRP", "SMS_OTP", "EMAIL_OTP"]
        )
        let selection = AuthClientSignInStep.continueSignInWithFirstFactorSelection(Set(factors))
        for factor in factors {
            let engine = EngineAuthFactorType(factor)
            XCTAssertEqual(factor.challengeResponse, engine.challengeResponse)
            XCTAssertEqual(EngineAuthFactorType(rawValue: factor.challengeResponse), engine)
            XCTAssertNotEqual(factor.challengeResponse, factor.rawValue)
            XCTAssertNoThrow(try SessionCore.validate(factor.challengeResponse, for: selection), "\(factor)")
        }
    }

    /// Test that every client flow maps to its engine flow, and none to the deprecated `custom`
    ///
    /// - Given: every client flow, `userAuth` with no preferred factor and with each factor
    /// - When:
    ///    - each is mapped to the engine
    /// - Then:
    ///    - it is the engine flow of the same name, with the factor mapped; `custom` is never produced
    ///
    func testAuthFlowTypesMapToTheEngine() {
        let rows: [(AuthClientAuthFlowType, EngineAuthFlowType)] = [
            (.userSRP, .userSRP),
            (.customWithSRP, .customWithSRP),
            (.customWithoutSRP, .customWithoutSRP),
            (.userPassword, .userPassword),
            (.userAuth(preferredFirstFactor: nil), .userAuth(preferredFirstFactor: nil)),
            (.userAuth(preferredFirstFactor: .emailOTP), .userAuth(preferredFirstFactor: .emailOTP)),
            (.userAuth(preferredFirstFactor: .passwordSRP), .userAuth(preferredFirstFactor: .passwordSRP))
        ]
        for (client, engine) in rows {
            let mapped = EngineAuthFlowType(client)
            XCTAssertEqual(mapped, engine, "\(client)")
            XCTAssertNotEqual(mapped, .custom, "\(client)")
        }
        XCTAssertEqual(Set(rows.map { Self.flowCaseIndex($0.0) }), Set(0 ..< 5))
    }

    /// Test that delivery destinations map case to case, with their values
    ///
    /// - Given: every engine destination, with a value and without one
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - it is the client case of the same name, with the same value
    ///
    func testDeliveryDestinationsMapCaseToCase() {
        let rows: [(EngineDeliveryDestination, AuthClientDeliveryDestination)] = [
            (.email("a***@example.com"), .email("a***@example.com")),
            (.phone(nil), .phone(nil)),
            (.sms("+1***"), .sms("+1***")),
            (.unknown("x"), .unknown("x"))
        ]
        for (engine, client) in rows {
            XCTAssertEqual(AuthClientDeliveryDestination(engine), client)
        }
        XCTAssertEqual(Set(rows.map { Self.destinationCaseIndex($0.0) }), Set(0 ..< 4))
    }

    /// Test that the delivery details' attribute, a Cognito name in the engine, becomes the client's key
    ///
    /// - Given: code delivery details naming every standard attribute, a custom one, an unknown one, and none
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - a standard name is its key (the inverse of `cognitoName`), `custom:team` is `.custom("team")`, an
    ///      unknown name is `.unknown` unchanged, and no attribute stays `nil`, as the plugin's
    ///      `AuthUserAttributeKey(rawValue:)` reads them
    ///
    func testDeliveryDetailsAttributeUsesTheCognitoNameTable() {
        for key in AuthClientUserAttributeKey.standardKeys {
            let details = EngineCodeDeliveryDetails(destination: .email(nil), attributeKey: key.cognitoName)
            XCTAssertEqual(AuthClientCodeDeliveryDetails(details).attributeKey, key, key.cognitoName)
        }
        // Compiler-checked, not a count: `standardKeyCaseIndex` switches over every case
        // with no `default:`, so a new key fails to compile until it has an index, and the list must hold
        // every index, in order, exactly once.
        XCTAssertEqual(
            AuthClientUserAttributeKey.standardKeys.map(Self.standardKeyCaseIndex),
            Array(0 ... Self.lastStandardKeyCaseIndex)
        )
        for key in AuthClientUserAttributeKey.standardKeys {
            XCTAssertEqual(AuthClientUserAttributeKey(cognitoName: key.cognitoName), key, key.cognitoName)
        }
        let rows: [(String?, AuthClientUserAttributeKey?)] = [
            ("custom:team", .custom("team")),
            ("custom:", .custom("")),
            ("dev:custom:team", .unknown("dev:custom:team")),
            ("Email", .unknown("Email")),
            (nil, nil)
        ]
        for (name, key) in rows {
            let details = EngineCodeDeliveryDetails(destination: .email("e"), attributeKey: name)
            XCTAssertEqual(AuthClientCodeDeliveryDetails(details), AuthClientCodeDeliveryDetails(destination: .email("e"), attributeKey: key))
        }
    }

    /// Test that tokens and credentials copy their fields, and drop the tokens' deprecated expiration
    ///
    /// - Given: engine user pool tokens and AWS credentials
    /// - When:
    ///    - they are mapped
    /// - Then:
    ///    - every field is copied; the client tokens have no expiration
    ///
    func testTokensAndCredentialsCopyTheirFields() {
        let tokens = EngineUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh", expiration: Date())
        XCTAssertEqual(AuthClientUserPoolTokens(tokens), AuthClientUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh"))

        let expiration = Date(timeIntervalSince1970: 1_800_000_000)
        let credentials = EngineAWSCredentials(accessKeyId: "a", secretAccessKey: "s", sessionToken: "t", expiration: expiration)
        XCTAssertEqual(
            CognitoAWSCredentials(credentials),
            CognitoAWSCredentials(accessKeyId: "a", secretAccessKey: "s", sessionToken: "t", expiration: expiration)
        )
    }

    // MARK: Errors

    /// Test that the service error codes map case for case, in the same order
    ///
    /// - Given: every engine service error code
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - it is the client code of the same name, at the same position of `allCases`; there are 34
    ///
    func testServiceErrorCodesMapCaseForCase() {
        let mapped = EngineServiceErrorCode.allCases.map(AuthClientServiceErrorCode.init)
        XCTAssertEqual(mapped, AuthClientServiceErrorCode.allCases)
        XCTAssertEqual(mapped.count, 34)
        for (engine, client) in zip(EngineServiceErrorCode.allCases, mapped) {
            XCTAssertEqual(String(describing: engine), String(describing: client))
        }
    }

    /// Test that every engine error maps to its client case, carrying the plugin's strings and the engine error
    ///
    /// - Given: one engine error per case, each with an underlying error
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - it is the client case the spec's table names (`signedOut` is `notSignedIn`); its description and
    ///      recovery suggestion are the engine's (the plugin's `AuthError` strings, `unknown`'s prefix included);
    ///      its underlying error is the engine error; the validation field and the service code are kept
    ///
    func testEveryEngineErrorMapsToItsClientCase() throws {
        let underlying = EngineServiceErrorCode.codeMismatch
        let rows: [(EngineAuthError, AuthClientError.Kind)] = [
            (.configuration("d", "s", underlying), .configuration),
            (.service("d", "s", underlying), .service(.codeMismatch)),
            (.unknown("d", underlying), .unknown),
            (.validation("field", "d", "s", underlying), .validation(field: "field")),
            (.notAuthorized("d", "s", underlying), .notAuthorized),
            (.invalidState("d", "s", underlying), .invalidState),
            (.signedOut("d", "s", underlying), .notSignedIn),
            (.sessionExpired("d", "s", underlying), .sessionExpired)
        ]
        for (engine, kind) in rows {
            let client = AuthClientError(engine: engine)
            XCTAssertEqual(client.kind, kind, "\(engine)")
            XCTAssertEqual(client.errorDescription, engine.errorDescription, "\(engine)")
            XCTAssertEqual(client.recoverySuggestion, engine.recoverySuggestion, "\(engine)")
            // `EngineAuthError ==` is the plugin's payload-blind one, and never equates two `.unknown`s: compare cases.
            let underlying = try XCTUnwrap(client.underlyingError as? EngineAuthError, "\(engine)")
            XCTAssertEqual(Self.errorCaseIndex(underlying), Self.errorCaseIndex(engine), "\(engine)")
            XCTAssertEqual(underlying.errorDescription, engine.errorDescription, "\(engine)")
        }
        XCTAssertEqual(Set(rows.map { Self.errorCaseIndex($0.0) }), Set(0 ..< 8))
        XCTAssertEqual(AuthClientError(engine: .unknown("boom")).errorDescription, "Unexpected error occurred with message: boom")
    }

    /// Test that a service error keeps its code only when the engine put one underneath
    ///
    /// - Given: engine service errors with each code underneath, with a non-code error, and with none
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - each code maps case for case, except `userCancelled` (below); the other two have no code
    ///
    func testServiceErrorsCarryTheirCode() {
        for code in EngineServiceErrorCode.allCases where code != .userCancelled {
            guard case .service(let mapped, _, _, _) = AuthClientError(engine: .service("d", "s", code)) else {
                return XCTFail("\(code) is not a service error")
            }
            XCTAssertEqual(mapped, AuthClientServiceErrorCode(code))
        }
        for underlying in [URLError(.notConnectedToInternet) as Error?, nil] {
            guard case .service(let mapped, _, _, _) = AuthClientError(engine: .service("d", "s", underlying)) else {
                return XCTFail("not a service error")
            }
            XCTAssertNil(mapped)
        }
    }

    /// Test that an engine recovery suggestion an app cannot act on is replaced with client text
    ///
    /// - Given: engine service errors with no service code, an underlying error, and a suggestion that is the
    ///   engine's "report a bug" text or empty; a service error with a code and the "report a bug" text; a
    ///   service error with no code and a suggestion of its own; one with the "report a bug" text and nothing
    ///   underneath (`noCredentialsToRefresh`); engine configuration errors with an empty and a non-empty
    ///   suggestion
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - the code-less "report a bug" and empty suggestions become the client's network-or-service text,
    ///      which asks for no bug report; the empty configuration suggestion becomes the client's configuration
    ///      text; every other suggestion, and every description, is the engine's
    ///
    func testUnhelpfulEngineRecoverySuggestionsAreReplaced() {
        let reportBug = EngineErrorMessages.reportBugToAWS(function: "authError")
        XCTAssertTrue(reportBug.hasPrefix(AuthClientError.reportBugPrefix), "the engine's text changed: \(reportBug)")

        for suggestion in [reportBug, ""] {
            let mapped = AuthClientError(engine: .service("Service error occurred", suggestion, URLError(.timedOut)))
            XCTAssertEqual(mapped.kind, .service(nil))
            XCTAssertEqual(mapped.errorDescription, "Service error occurred")
            XCTAssertEqual(mapped.recoverySuggestion, AuthClientError.clientServiceSuggestion)
            XCTAssertFalse(mapped.recoverySuggestion.contains("bug"), mapped.recoverySuggestion)
        }
        let coded = AuthClientError(engine: .service("d", reportBug, EngineServiceErrorCode.limitExceeded))
        XCTAssertEqual(coded.recoverySuggestion, reportBug)
        let own = AuthClientError(engine: .service("d", "Wait, then retry.", nil))
        XCTAssertEqual(own.recoverySuggestion, "Wait, then retry.")
        // Nothing underneath: the engine's own state, as `FetchSessionError.noCredentialsToRefresh`. Not a network error.
        let noCredentials = AuthClientError(engine: .service("No credentials found to refresh", reportBug, nil))
        XCTAssertEqual(noCredentials.recoverySuggestion, reportBug)

        let emptyConfiguration = AuthClientError(engine: .configuration("UserPool configuration is missing", ""))
        XCTAssertEqual(emptyConfiguration.kind, .configuration)
        XCTAssertEqual(emptyConfiguration.recoverySuggestion, AuthClientError.clientConfigurationSuggestion)
        XCTAssertFalse(emptyConfiguration.recoverySuggestion.isEmpty)
        let configuration = AuthClientError(engine: .configuration("d", "Add a user pool."))
        XCTAssertEqual(configuration.recoverySuggestion, "Add a user pool.")
    }

    /// Test that an engine recovery suggestion naming the plugin's `Auth.*` calls names the client's calls
    ///
    /// - Given: the engine's authorization `sessionExpired` error, and one engine error for each of the engine's
    ///   `AuthPluginErrorConstants` whose recovery suggestion names an `Auth.*` call
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - the engine's own strings are unchanged (the plugin's error-catalogue golden depends on them)
    ///    - each client recovery suggestion is the pinned client text, which names no `Auth.` or `Amplify.` call;
    ///      the description is the engine's (the case is checked for `sessionExpired`)
    ///
    func testRecoverySuggestionsNamingThePluginsCallsNameTheClients() throws {
        let sessionExpired = AuthorizationError.sessionExpired(error: FixtureError(description: "expired")).engineError
        XCTAssertEqual(sessionExpired.recoverySuggestion, "Invoke Auth.signIn to re-authenticate the user")
        let mapped = AuthClientError(engine: sessionExpired)
        XCTAssertEqual(mapped.kind, .sessionExpired)
        XCTAssertEqual(mapped.errorDescription, "Session expired")
        XCTAssertEqual(mapped.recoverySuggestion, "Call signIn to sign the user in again.")

        let signIn = "Call signIn to sign the user in again."
        let signInOrGuest = "Call signIn to sign a user in, or enable unauthenticated access in the Cognito identity pool."
        let signInThenFetch = "Call signIn to sign a user in, then call fetchAuthSession."
        let getCurrentUser = "Call getCurrentUser to get the signed-in user, then make the request again."
        let rows: [(AuthPluginErrorString, String, String)] = [
            (AuthPluginErrorConstants.userInvalidError, "Get the current user Auth.getCurrentUser() and make the request", getCurrentUser),
            (AuthPluginErrorConstants.identityIdSignOutError, "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool", signInOrGuest),
            (AuthPluginErrorConstants.awsCredentialsSignOutError, "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool", signInOrGuest),
            (AuthPluginErrorConstants.cognitoTokensSignOutError, "Call Auth.signIn to sign in a user and then call Auth.fetchSession", signInThenFetch),
            (AuthPluginErrorConstants.userSubSignOutError, "Call Auth.signIn to sign in a user and then call Auth.fetchSession", signInThenFetch),
            (AuthPluginErrorConstants.identityIdSessionExpiredError, "Invoke Auth.signIn to re-authenticate the user", signIn),
            (AuthPluginErrorConstants.awsCredentialsSessionExpiredError, "Invoke Auth.signIn to re-authenticate the user", signIn),
            (AuthPluginErrorConstants.usersubSessionExpiredError, "Invoke Auth.signIn to re-authenticate the user", signIn),
            (AuthPluginErrorConstants.cognitoTokensSessionExpiredError, "Invoke Auth.signIn to re-authenticate the user", signIn)
        ]
        for (constant, engineText, clientText) in rows {
            XCTAssertEqual(constant.recoverySuggestion, engineText, "the engine's text changed")
            for engine in [
                EngineAuthError.signedOut(constant.errorDescription, constant.recoverySuggestion),
                .sessionExpired(constant.errorDescription, constant.recoverySuggestion),
                .invalidState(constant.errorDescription, constant.recoverySuggestion)
            ] {
                let client = AuthClientError(engine: engine)
                XCTAssertEqual(client.errorDescription, constant.errorDescription, "\(engine)")
                XCTAssertEqual(client.recoverySuggestion, clientText, "\(engine)")
            }
        }
        XCTAssertEqual(Set(AuthClientError.clientRecoverySuggestions.keys), Set(rows.map(\.1)))
        for text in AuthClientError.clientRecoverySuggestions.values {
            XCTAssertFalse(text.contains("Auth."), text)
            XCTAssertFalse(text.contains("Amplify."), text)
        }
    }

    /// Test that an engine text naming the plugin's MFA type names the client's
    ///
    /// - Given: the engine's MFA setup refusal, as `UserPoolSignInHelper` builds it with
    ///   `EngineMFAType.legacyDescription(of:)` (`[Amplify.MFAType.<type>, …]`), mapped by the engine to `.service`
    /// - When:
    ///    - it is mapped
    /// - Then:
    ///    - the engine's description is unchanged; the client's names `AuthClientMFAType.<type>` for each type, and
    ///      is otherwise the engine's text; a text naming no MFA type is unchanged
    ///
    func testTextsNamingThePluginsMFATypeNameTheClients() {
        let message = "Cannot initiate MFA setup from available Types: [Amplify.MFAType.sms, Amplify.MFAType.totp]"
        let engine = SignInError.invalidServiceResponse(message: message).engineError
        XCTAssertEqual(engine.errorDescription, message)
        let mapped = AuthClientError(engine: engine)
        XCTAssertEqual(mapped.kind, .service(nil))
        XCTAssertEqual(
            mapped.errorDescription,
            "Cannot initiate MFA setup from available Types: [AuthClientMFAType.sms, AuthClientMFAType.totp]"
        )
        XCTAssertEqual(
            AuthClientError(engine: .unknown("[Amplify.MFAType.email]")).errorDescription,
            "Unexpected error occurred with message: [AuthClientMFAType.email]"
        )
        XCTAssertEqual(AuthClientError(engine: .service("Service error occurred", "Retry.")).errorDescription, "Service error occurred")
    }

    /// Test that a service response that could not be read is a temporary service problem, not a bug to report
    ///
    /// - Given: an engine service error with, underneath, Foundation's JSON reader's error for a body that is not JSON
    ///   (`NSCocoaErrorDomain` 3840, as for an HTML error page from the service's edge); and, for contrast, ones with
    ///   a `DecodingError` (JSON that does not fit the model: likely a client bug) and another Cocoa error
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - the first is `.service` with no code, the engine's description and the error underneath, and the
    ///      "temporary problem, retry" recovery suggestion; the contrasts keep the engine's suggestion
    ///
    func testAnUnreadableServiceResponseIsATemporaryServiceProblem() {
        let notJSON = NSError(domain: NSCocoaErrorDomain, code: 3_840, userInfo: [
            "NSDebugDescription": "JSON text did not start with array or object and option to allow fragments not set."
        ])
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "not JSON"))
        for underlying in [notJSON as Error] {
            let mapped = AuthClientError(engine: .service("Service error occurred", "Report a bug.", underlying))
            guard case .service(let code, let description, let suggestion, let error) = mapped else {
                return XCTFail("not a service error: \(mapped)")
            }
            XCTAssertNil(code)
            XCTAssertEqual(description, "Service error occurred")
            XCTAssertEqual(suggestion, AuthClientError.unreadableServiceResponseSuggestion)
            XCTAssertNotNil(error as? EngineAuthError)
        }
        let other = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
        for contrast in [decoding as Error, other] {
            let mapped = AuthClientError(engine: .service("d", "Report a bug.", contrast))
            XCTAssertEqual(mapped.recoverySuggestion, "Report a bug.", "\(contrast)")
        }
        // The engine's own "report a bug" text stays for a response that does not fit the model: likely a client bug.
        let reportBug = EngineErrorMessages.reportBugToAWS(function: "authError")
        XCTAssertEqual(AuthClientError(engine: .service("d", reportBug, decoding)).recoverySuggestion, reportBug)
        XCTAssertEqual(
            AuthClientError(engine: .service("d", reportBug, notJSON)).recoverySuggestion,
            AuthClientError.unreadableServiceResponseSuggestion
        )
    }

    /// Test that a cancellation has one shape: the engine's `userCancelled` service code is never `.service`
    ///
    /// - Given: the engine's service error with `userCancelled` underneath
    /// - When:
    ///    - it is mapped, on the general path and on the confirm path
    /// - Then:
    ///    - it is `.userCancelled` with the engine's strings and the engine error underneath
    ///
    func testUserCancelledIsNeverAServiceError() {
        let engine = EngineAuthError.service("cancelled", "retry", EngineServiceErrorCode.userCancelled)
        for error in [
            AuthClientError(engine: engine),
            AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: true),
            AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: false)
        ] {
            guard case .userCancelled(let description, let suggestion, let underlying) = error else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, engine.errorDescription)
            XCTAssertEqual(suggestion, engine.recoverySuggestion)
            XCTAssertTrue(underlying is EngineAuthError)
        }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Test that a local WebAuthn ceremony's failure is never `.service`
    ///
    /// - Given: the engine's service errors for the ceremony, as `WebAuthnError` makes them: the platform's
    ///   `ASAuthorizationError` underneath (`.canceled`, 1006, `.failed`, `.notHandled`), for registration
    ///   and assertion; and options the engine could not read (`WebAuthnCredentialError` underneath)
    /// - When:
    ///    - each is mapped, on the general path and on the confirm path
    /// - Then:
    ///    - `.canceled` is `.userCancelled`; 1006 `.webAuthnCeremonyFailed(.credentialAlreadyExists)`; any other
    ///      code `.webAuthnCeremonyFailed(.failed)`; unreadable options
    ///      `.webAuthnCeremonyFailed(.invalidCredential)`; each with the engine's strings, and the platform's
    ///      (or the decoding) error underneath
    ///
    func testWebAuthnCeremonyFailuresAreNeverServiceErrors() throws {
        let alreadyExists = try XCTUnwrap(ASAuthorizationError.Code(rawValue: 1_006))
        let cases: [(WebAuthnError, AuthClientError.Kind)] = [
            (.creationFailed(error: ASAuthorizationError(.canceled)), .userCancelled),
            (.assertionFailed(error: ASAuthorizationError(.canceled)), .userCancelled),
            (.creationFailed(error: ASAuthorizationError(alreadyExists)), .webAuthnCeremonyFailed(.credentialAlreadyExists)),
            (.creationFailed(error: ASAuthorizationError(.failed)), .webAuthnCeremonyFailed(.failed)),
            (.assertionFailed(error: ASAuthorizationError(.failed)), .webAuthnCeremonyFailed(.failed)),
            (.assertionFailed(error: ASAuthorizationError(.notHandled)), .webAuthnCeremonyFailed(.failed)),
            (
                .unknown(message: "Unable to associate WebAuthn credential", error: WebAuthnCredentialError<CredentialCreationOptions>.missingValue("challenge", type: CredentialCreationOptions.self)),
                .webAuthnCeremonyFailed(.invalidCredential)
            )
        ]

        for (webAuthnError, kind) in cases {
            let engine = webAuthnError.engineError
            for error in [
                AuthClientError(engine: engine),
                AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: false)
            ] {
                XCTAssertEqual(error.kind, kind, "\(webAuthnError)")
                XCTAssertEqual(error.errorDescription, engine.errorDescription)
                XCTAssertEqual(error.recoverySuggestion, engine.recoverySuggestion)
                if case .webAuthnCeremonyFailed(.invalidCredential, _, _, _) = error {
                    XCTAssertTrue(error.underlyingError is AnyWebAuthnCredentialError)
                } else {
                    XCTAssertTrue(error.underlyingError is ASAuthorizationError, "\(webAuthnError)")
                }
            }
        }
    }
    #endif

    /// Test that a client error the engine hands back (a runner's own, such as the sheet lease's refusal) is
    /// itself, never wrapped in `.service`
    ///
    /// - Given: the engine's service error with an `AuthClientError.browserBusy(holder:)` underneath, as the
    ///   engine reports an error it cannot convert (`WebAuthnError.unknown`)
    /// - When:
    ///    - it is mapped
    /// - Then:
    ///    - it is that `browserBusy`, holder and strings unchanged
    ///
    func testAClientErrorUnderneathIsItself() {
        let busy = AuthClientError.browserBusy(holder: ClientFixtures.id("home"), "busy", "wait")
        let engine = EngineAuthError.service("An unknown error type was thrown by the service.", "file a bug", busy)

        let mapped = AuthClientError(engine: engine)

        XCTAssertTrue(mapped.isEquivalent(to: busy), "\(mapped)")
    }

    /// Test that only an expired challenge session is `challengeExpired` on the confirm path
    ///
    /// - Given: the engine's `notAuthorized` for Cognito's expired-session message (in any case), for a wrong
    ///   password, and other engine errors
    /// - When:
    ///    - each is mapped as a failure answering a challenge
    /// - Then:
    ///    - the expired session is `challengeExpired` with Cognito's message and the engine error underneath;
    ///      the wrong password stays `notAuthorized` (retryable); the others map as everywhere else
    ///
    func testOnlyAnExpiredChallengeSessionIsChallengeExpired() {
        for message in ["Invalid session for the user, session is expired.", "INVALID SESSION FOR THE USER, SESSION IS EXPIRED."] {
            let engine = EngineAuthError.notAuthorized(message, "s")
            let client = AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: true)
            XCTAssertEqual(client.kind, .challengeExpired)
            XCTAssertEqual(client.errorDescription, message)
            XCTAssertEqual(client.underlyingError as? EngineAuthError, engine)
        }
        let others: [(EngineAuthError, AuthClientError.Kind)] = [
            (.notAuthorized("Incorrect username or password.", "s"), .notAuthorized),
            (.service("session is expired", "s", EngineServiceErrorCode.codeExpired), .service(.codeExpired)),
            (.sessionExpired("session is expired", "s"), .sessionExpired),
            (.invalidState("d", "s"), .invalidState)
        ]
        for (engine, kind) in others {
            XCTAssertEqual(AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: true).kind, kind, "\(engine)")
        }
    }

    /// Test that an invalid session, or a message-less `NotAuthorizedException`, is `challengeExpired`, and a
    /// wrong password stays retryable
    ///
    /// - Given: the engine's own mapping of `NotAuthorizedException` for the expired-session message, the
    ///   invalid-session message without "expired", no message, and a wrong password
    /// - When:
    ///    - each is mapped as a failure answering a challenge
    /// - Then:
    ///    - the three dead sessions are `challengeExpired`; the wrong password stays `notAuthorized`
    ///    - the message-less constant is the engine's fallback text
    ///
    func testAnInvalidOrMessagelessSessionIsChallengeExpired() {
        let dead: [String?] = [
            "Invalid session for the user, session is expired.",
            "Invalid session for the user.",
            nil
        ]
        for message in dead {
            let engine = AWSCognitoIdentityProvider.NotAuthorizedException(message: message).engineError
            XCTAssertEqual(AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: true).kind, .challengeExpired, "\(String(describing: message))")
        }
        let wrongPassword = AWSCognitoIdentityProvider.NotAuthorizedException(message: "Incorrect username or password.").engineError
        XCTAssertEqual(AuthClientError(engineConfirmingSignIn: wrongPassword, rejectedByUserPool: true).kind, .notAuthorized)
        // The same messages without the user pool's rejection behind them (an identity pool step, say) are
        // never an expired challenge.
        for message in dead {
            let engine = AWSCognitoIdentityProvider.NotAuthorizedException(message: message).engineError
            XCTAssertEqual(AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: false).kind, .notAuthorized)
        }
        XCTAssertEqual(
            AWSCognitoIdentityProvider.NotAuthorizedException(message: nil).engineError.errorDescription,
            AuthClientError.messagelessNotAuthorized
        )
    }

    /// Test that sign-out failures become the outcome's errors, without their tokens
    ///
    /// - Given: an engine revoke failure and a global sign-out failure, each carrying a token
    /// - When:
    ///    - the outcome is built from each, from both and from neither
    /// - Then:
    ///    - each failure's engine error is mapped into its field; neither token appears in the outcome
    ///
    func testSignOutFailuresBecomeTheOutcome() {
        let revoke = EngineRevokeTokenFailure(refreshToken: "refresh-token", error: .service("revoke", "s"))
        let global = EngineGlobalSignOutFailure(accessToken: "access-token", error: .notAuthorized("global", "s"))

        XCTAssertTrue(EngineSignOutOutcome(revokeFailure: nil, globalSignOutFailure: nil).isComplete)
        let both = EngineSignOutOutcome(revokeFailure: revoke, globalSignOutFailure: global)
        XCTAssertEqual(both.revokeError?.kind, .service(nil))
        XCTAssertEqual(both.revokeError?.errorDescription, "revoke")
        XCTAssertEqual(both.globalSignOutError?.kind, .notAuthorized)
        XCTAssertEqual(both.globalSignOutError?.errorDescription, "global")
        XCTAssertEqual(EngineSignOutOutcome(revokeFailure: revoke, globalSignOutFailure: nil).globalSignOutError?.kind, nil)
        XCTAssertEqual(EngineSignOutOutcome(revokeFailure: nil, globalSignOutFailure: global).revokeError?.kind, nil)
        let description = "\(both)"
        XCTAssertFalse(description.contains("refresh-token"))
        XCTAssertFalse(description.contains("access-token"))
    }

    // MARK: Exhaustive case indexes

    /// The highest index `standardKeyCaseIndex` gives. Raise it with the new case's arm.
    private static let lastStandardKeyCaseIndex = 19

    /// Each standard key's position in declaration order; `nil` for the two keys with no fixed name. No
    /// `default:`: a new case fails to compile here.
    private static func standardKeyCaseIndex(_ key: AuthClientUserAttributeKey) -> Int? {
        switch key {
        case .address: return 0
        case .birthDate: return 1
        case .email: return 2
        case .emailVerified: return 3
        case .familyName: return 4
        case .gender: return 5
        case .givenName: return 6
        case .locale: return 7
        case .middleName: return 8
        case .name: return 9
        case .nickname: return 10
        case .phoneNumber: return 11
        case .phoneNumberVerified: return 12
        case .picture: return 13
        case .preferredUsername: return 14
        case .profile: return 15
        case .sub: return 16
        case .updatedAt: return 17
        case .website: return 18
        case .zoneInfo: return 19
        case .custom, .unknown: return nil
        }
    }

    private static func signInStepCaseIndex(_ step: EngineSignInStep) -> Int {
        switch step {
        case .confirmSignInWithSMSMFACode: return 0
        case .confirmSignInWithCustomChallenge: return 1
        case .confirmSignInWithNewPassword: return 2
        case .confirmSignInWithPassword: return 3
        case .confirmSignInWithTOTPCode: return 4
        case .continueSignInWithTOTPSetup: return 5
        case .continueSignInWithMFASelection: return 6
        case .continueSignInWithEmailMFASetup: return 7
        case .continueSignInWithMFASetupSelection: return 8
        case .confirmSignInWithOTP: return 9
        case .continueSignInWithFirstFactorSelection: return 10
        case .resetPassword: return 11
        case .confirmSignUp: return 12
        case .done: return 13
        }
    }

    private static func signInStepCaseIndex(_ step: AuthClientSignInStep) -> Int {
        switch step {
        case .confirmSignInWithSMSMFACode: return 0
        case .confirmSignInWithCustomChallenge: return 1
        case .confirmSignInWithNewPassword: return 2
        case .confirmSignInWithPassword: return 3
        case .confirmSignInWithTOTPCode: return 4
        case .continueSignInWithTOTPSetup: return 5
        case .continueSignInWithMFASelection: return 6
        case .continueSignInWithEmailMFASetup: return 7
        case .continueSignInWithMFASetupSelection: return 8
        case .confirmSignInWithOTP: return 9
        case .continueSignInWithFirstFactorSelection: return 10
        case .resetPassword: return 11
        case .confirmSignUp: return 12
        case .done: return 13
        }
    }

    private static func mfaCaseIndex(_ type: EngineMFAType) -> Int {
        switch type {
        case .sms: return 0
        case .totp: return 1
        case .email: return 2
        }
    }

    private static func factorCaseIndex(_ factor: EngineAuthFactorType) -> Int {
        switch factor {
        case .password: return 0
        case .passwordSRP: return 1
        case .smsOTP: return 2
        case .emailOTP: return 3
        #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn: return 4
        #endif
        }
    }

    private static func flowCaseIndex(_ flow: AuthClientAuthFlowType) -> Int {
        switch flow {
        case .userSRP: return 0
        case .customWithSRP: return 1
        case .customWithoutSRP: return 2
        case .userPassword: return 3
        case .userAuth: return 4
        }
    }

    private static func destinationCaseIndex(_ destination: EngineDeliveryDestination) -> Int {
        switch destination {
        case .email: return 0
        case .phone: return 1
        case .sms: return 2
        case .unknown: return 3
        }
    }

    private static func errorCaseIndex(_ error: EngineAuthError) -> Int {
        switch error {
        case .configuration: return 0
        case .service: return 1
        case .unknown: return 2
        case .validation: return 3
        case .notAuthorized: return 4
        case .invalidState: return 5
        case .signedOut: return 6
        case .sessionExpired: return 7
        }
    }
}
