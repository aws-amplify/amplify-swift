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
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import SmithyHTTPAPI
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The engine -> client mappers, directly, case for case, rather than only transitively (engine <-> plugin by
/// the plugin's goldens, plugin <-> client by the model parity tests).
///
/// Every table has one row per engine case. The `…CaseIndex` helpers are exhaustive switches with no
/// `default:`, so a new engine case does not compile here until it has an index. Each test checks that its rows
/// cover every index from 0 to the switch's `last…CaseIndex`, which sits beside the switches: raised with the new
/// arm, it fails the test until the new case has its row. The switches cannot check the constant itself.
final class EngineMappingTests: XCTestCase {

    private static let details = EngineCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: "phone_number")
    private static let clientDetails = AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: .phoneNumber)
    private static let info = ["key": "value"]

    // MARK: Sign-in steps

    /// Test that every engine sign-in step maps to the client step of the same name and payload
    ///
    /// - Given: one engine step per case, in declaration order, with every payload filled, and
    ///   the optional payloads also empty
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
            (.confirmSignInWithNewPassword(Self.info), .confirmSignInWithNewPassword(Self.info)),
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
            (.confirmSignUp(Self.info), .confirmSignUp(Self.info)),
            (.confirmSignUp(nil), .confirmSignUp(nil)),
            (.done, .done)
        ]

        for (engine, client) in rows {
            XCTAssertEqual(AuthClientSignInStep(engine), client, "\(engine)")
            XCTAssertEqual(Self.signInStepCaseIndex(engine), Self.signInStepCaseIndex(client), "\(engine)")
        }
        XCTAssertEqual(Set(rows.map { Self.signInStepCaseIndex($0.0) }), Set(0 ... Self.lastSignInStepCaseIndex))
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
        XCTAssertEqual(Set(rows.map { Self.mfaCaseIndex($0.0) }), Set(0 ... Self.lastMFACaseIndex))
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
        // WebAuthn, the last index where the platform has it, is only a value where the OS has it too.
        var lastAvailable = Self.lastFactorCaseIndex
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            rows.append((.webAuthn, .webAuthn))
        } else {
            lastAvailable -= 1
        }
        #endif
        for (engine, client) in rows {
            XCTAssertEqual(AuthClientFactorType(engine), client)
            XCTAssertEqual(EngineAuthFactorType(client), engine)
            XCTAssertEqual(AuthClientFactorType(EngineAuthFactorType(client)), client)
            XCTAssertNotEqual(engine.rawValue, client.rawValue)
        }
        XCTAssertEqual(Set(rows.map { Self.factorCaseIndex($0.0) }), Set(0 ... lastAvailable))
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
            XCTAssertEqual(EngineAuthFactorType(rawValue: factor.challengeResponse, logger: ClientEngineLogger()), engine)
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
        XCTAssertEqual(Set(rows.map { Self.flowCaseIndex($0.0) }), Set(0 ... Self.lastFlowCaseIndex))
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
        XCTAssertEqual(Set(rows.map { Self.destinationCaseIndex($0.0) }), Set(0 ... Self.lastDestinationCaseIndex))
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
        XCTAssertEqual(Set(rows.map { Self.errorCaseIndex($0.0) }), Set(0 ... Self.lastErrorCaseIndex))
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
            let mapped = AuthClientError(engine: .service("Service error occurred", suggestion, FixtureError(description: "x")))
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

    /// A failure to reach Cognito is a retryable service error with the client's network texts, wherever the engine
    /// reports it: as `.unknown` with an empty message (the sign-in flows), or as a code-less `.service` (a refresh,
    /// or a revoke's empty texts).
    ///
    /// - Given: engine `.unknown` and `.service` errors with URL loading, CFNetwork and POSIX network failures
    ///   underneath; URL loading failures about a response, App Transport Security, authentication and a
    ///   cancellation; a POSIX error that is not a network failure; an `.unknown` with a service code;
    ///   the global sign-out's placeholder revoke error (empty texts, nothing underneath); and a code-less `.service`
    ///   with empty texts over an error that is not a network failure
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - every network failure is `.service` with no code, the network description and suggestion, and the network
    ///      error itself underneath
    ///    - a cancelled load, a response that arrived but was bad, an App Transport Security or authentication
    ///      failure, a bad URL and the other POSIX error don't get the network description; a code-less `.service`
    ///      over the cancelled load or the POSIX error, neither a transport failure, keeps its own; the coded
    ///      `.unknown` stays `.unknown`
    ///    - the placeholder keeps its empty texts; the other empty one gets the generic service description
    func testANetworkFailureIsARetryableServiceError() {
        let network: [Error] = [
            URLError(.cannotFindHost),
            URLError(.cannotConnectToHost),
            URLError(.timedOut),
            URLError(.notConnectedToInternet),
            URLError(.networkConnectionLost),
            URLError(.dnsLookupFailed),
            URLError(.dataNotAllowed),
            URLError(.secureConnectionFailed),
            NSError(domain: "kCFErrorDomainCFNetwork", code: 2),
            NSError(domain: "kCFErrorDomainCFNetwork", code: NSURLErrorCannotFindHost),
            NSError(domain: NSPOSIXErrorDomain, code: Int(ECONNREFUSED)),
            NSError(domain: NSPOSIXErrorDomain, code: Int(ETIMEDOUT))
        ]
        for failure in network {
            for engine in [EngineAuthError.unknown("", failure), .service("", "", failure), .service("Service error occurred", "", failure)] {
                let mapped = AuthClientError(engine: engine)
                XCTAssertEqual(mapped.kind, .service(nil), "\(engine)")
                XCTAssertEqual(mapped.errorDescription, AuthClientError.networkFailureDescription, "\(engine)")
                XCTAssertEqual(mapped.recoverySuggestion, AuthClientError.clientServiceSuggestion, "\(engine)")
                // The network error itself, not the engine's error over it.
                let underlying = mapped.underlyingError as NSError?
                XCTAssertEqual(underlying?.domain, (failure as NSError).domain, "\(engine)")
                XCTAssertEqual(underlying?.code, (failure as NSError).code, "\(engine)")
            }
        }
        // Failures that reached the service, or never left the device for another reason, are not network failures.
        let notNetwork: [Error] = [
            URLError(.cancelled),
            URLError(.badServerResponse),
            URLError(.cannotParseResponse),
            URLError(.userCancelledAuthentication),
            URLError(.userAuthenticationRequired),
            URLError(.appTransportSecurityRequiresSecureConnection),
            URLError(.badURL),
            NSError(domain: "kCFErrorDomainCFNetwork", code: NSURLErrorBadServerResponse),
            NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
        ]
        for failure in notNetwork {
            for engine in [EngineAuthError.unknown("", failure), .service("Service error occurred", "", failure)] {
                XCTAssertNotEqual(AuthClientError(engine: engine).errorDescription, AuthClientError.networkFailureDescription, "\(engine)")
            }
        }
        // Neither is a transport failure either (`testATransportFailureIsAReadableServiceError` has the others).
        for failure in [URLError(.cancelled) as Error, NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))] {
            let service = AuthClientError(engine: .service("Service error occurred", "", failure))
            XCTAssertEqual(service.errorDescription, "Service error occurred", "\(failure)")
        }
        XCTAssertEqual(AuthClientError(engine: .unknown("d", EngineServiceErrorCode.codeMismatch)).kind, .unknown)

        let placeholder = AuthClientError(engine: .service("", "", nil))
        XCTAssertEqual(placeholder.errorDescription, "")
        XCTAssertEqual(placeholder.recoverySuggestion, "")
        let emptyOther = AuthClientError(engine: .service("", "", FixtureError(description: "x")))
        XCTAssertEqual(emptyOther.errorDescription, AuthClientError.emptyServiceFailureDescription)
        XCTAssertEqual(emptyOther.recoverySuggestion, AuthClientError.clientServiceSuggestion)
    }

    /// A Cognito failure the engine reports as `.unknown` is `.service` with no code, with a recovery suggestion that
    /// fits it, never the engine's "report a bug" text.
    ///
    /// - Given: engine `.unknown` errors over an error status the SDK does not model (`UnknownAWSHTTPServiceError`)
    ///   of 500, 503, 400 and 404; engine failures made from either pool's `InternalErrorException`, on its own and
    ///   inside the sign-in, WebAuthn, authorization, session and sign-up errors, and inside one of them inside another,
    ///   as the engine's mapping unwraps them, which the engine reports as
    ///   `.unknown` with nothing underneath; and an engine `.unknown` with no cause, with a cause that is not a
    ///   service error, and with another Cognito exception as its cause
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - each Cognito failure is `.service` with no code, with the engine's description and the engine error
    ///      underneath; the 5xx statuses and the internal errors suggest a retry, the 4xx statuses say the service
    ///      refused the request with an error the client does not recognise, and none asks for a bug report
    ///    - the others stay `.unknown`, with the engine's suggestion
    func testACognitoFailureReportedAsUnknownIsACodelessServiceError() throws {
        let fault = "The service could not complete the request, usually a temporary problem at the service. Retry the operation."
        let refusal = "The service refused the request with an error this client does not recognise. The description has the "
            + "service's status and message: check the request against it before retrying."
        XCTAssertEqual(AuthClientError.serviceFaultSuggestion, fault)
        XCTAssertEqual(AuthClientError.unrecognisedServiceErrorSuggestion, refusal)

        let statuses: [(HTTPStatusCode, String)] = [
            (.internalServerError, fault), (.serviceUnavailable, fault), (.badRequest, refusal), (.notFound, refusal)
        ]
        for (status, expected) in statuses {
            let unmodelled = UnknownAWSHTTPServiceError(
                httpResponse: HTTPResponse(body: .empty, statusCode: status),
                message: "fixture message",
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
            let engine = unmodelled.engineError
            let mapped = AuthClientError(engine: engine)
            XCTAssertEqual(mapped.kind, .service(nil), "\(status)")
            XCTAssertEqual(mapped.errorDescription, engine.errorDescription, "\(status)")
            XCTAssertTrue(mapped.errorDescription.contains("\(status.rawValue)"), mapped.errorDescription)
            XCTAssertEqual(mapped.recoverySuggestion, expected, "\(status)")
            XCTAssertFalse(mapped.recoverySuggestion.contains("bug"), "\(status)")
            XCTAssertNotNil(mapped.underlyingError as? EngineAuthError, "\(status)")
        }

        let userPool = AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        let identityPool = AWSCognitoIdentity.InternalErrorException(message: "boom")
        let failures: [(String, any EngineAuthErrorConvertible)] = [
            ("user pool", userPool),
            ("identity pool", identityPool),
            ("sign-in", SignInError.service(error: userPool)),
            ("WebAuthn sign-in", SignInError.webAuthn(.service(error: userPool))),
            ("authorization", AuthorizationError.service(error: identityPool)),
            ("session", AuthorizationError.sessionError(.service(identityPool), .noCredentials)),
            ("refresh", FetchSessionError.service(userPool)),
            ("sign-up", SignUpError.service(error: userPool)),
            ("nested", AuthorizationError.service(error: FetchSessionError.service(identityPool)))
        ]
        for (name, failure) in failures {
            let engine = failure.engineError
            guard case .unknown(_, nil) = engine else {
                return XCTFail("\(name): the engine's mapping changed: \(engine)")
            }
            let mapped = AuthClientError(engineFailure: failure)
            XCTAssertEqual(mapped.kind, .service(nil), name)
            XCTAssertEqual(mapped.errorDescription, "Unexpected error occurred with message: boom", name)
            XCTAssertEqual(mapped.recoverySuggestion, fault, name)
            XCTAssertNotNil(mapped.underlyingError as? EngineAuthError, name)
            // The confirm path's mapping keeps the cause too.
            let confirming = AuthClientError(engineConfirmingSignIn: engine, rejectedByUserPool: false, cause: failure as? Error)
            XCTAssertEqual(confirming.kind, .service(nil), name)
            XCTAssertEqual(confirming.recoverySuggestion, fault, name)
        }

        let engineText = EngineAuthError.unknown("boom").recoverySuggestion
        XCTAssertTrue(engineText.contains("file an issue"), engineText)
        let others: [(String, AuthClientError)] = [
            ("no cause", AuthClientError(engine: .unknown("boom"))),
            ("not a service error", AuthClientError(engine: .unknown("boom"), cause: SignInError.unknown(message: "boom"))),
            (
                "another exception",
                AuthClientError(engine: .unknown("boom"), cause: AWSCognitoIdentityProvider.InvalidParameterException(message: "boom"))
            )
        ]
        for (name, mapped) in others {
            XCTAssertEqual(mapped.kind, .unknown, name)
            XCTAssertEqual(mapped.recoverySuggestion, engineText, name)
        }
    }

    /// A transport failure that is not a network failure is a readable, retryable service error too, never an empty
    /// `.unknown`: an unreadable response gets the refresh path's suggestion, any other URL loading failure the
    /// client's network-or-service one. It reads the same whichever engine error carries it.
    ///
    /// - Given: a body that is not JSON, URL loading's `badServerResponse` and `cannotParseResponse` (also in the
    ///   CFNetwork domain), an App Transport Security refusal, an authentication failure and a bad URL, each under
    ///   an engine `.unknown` with an empty message, a code-less `.service` with the engine's "report a bug" text, one
    ///   with empty texts (a revoke's), and the passkey calls' fallback (`WebAuthnError.unknown`); and an `.unknown`
    ///   over a cancelled load, a POSIX error that is not a network failure, and a service code
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - the unreadable responses are `.service` with no code, "The service returned a response that could not be
    ///      read." and the retry suggestion; the other URL failures are `.service` with no code, "The service request
    ///      failed." and the network-or-service suggestion; each has the engine error underneath, and none asks for a
    ///      bug report or says it should not happen
    ///    - the cancelled load, the POSIX error and the coded one stay `.unknown`
    func testATransportFailureIsAReadableServiceError() {
        let unreadable: [Error] = [
            NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError),
            URLError(.badServerResponse),
            URLError(.cannotParseResponse),
            NSError(domain: "kCFErrorDomainCFNetwork", code: NSURLErrorBadServerResponse)
        ]
        let otherURLFailures: [Error] = [
            URLError(.appTransportSecurityRequiresSecureConnection),
            URLError(.userCancelledAuthentication),
            URLError(.userAuthenticationRequired),
            URLError(.badURL)
        ]
        let rows = unreadable.map { ($0, AuthClientError.unreadableResponseDescription, AuthClientError.unreadableServiceResponseSuggestion) }
            + otherURLFailures.map { ($0, AuthClientError.emptyServiceFailureDescription, AuthClientError.clientServiceSuggestion) }
        XCTAssertEqual(AuthClientError.unreadableResponseDescription, "The service returned a response that could not be read.")
        XCTAssertEqual(AuthClientError.emptyServiceFailureDescription, "The service request failed.")
        for (failure, description, suggestion) in rows {
            for engine in Self.transportFailureShapes(failure) {
                let mapped = AuthClientError(engine: engine)
                XCTAssertEqual(mapped.kind, .service(nil), "\(engine)")
                XCTAssertEqual(mapped.errorDescription, description, "\(engine)")
                XCTAssertEqual(mapped.recoverySuggestion, suggestion, "\(engine)")
                XCTAssertNotNil(mapped.underlyingError as? EngineAuthError, "\(engine)")
                XCTAssertFalse(mapped.recoverySuggestion.contains("bug"), "\(engine)")
                XCTAssertFalse(mapped.recoverySuggestion.contains("should not happen"), "\(engine)")
            }
        }
        for failure in [URLError(.cancelled) as Error, NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)), EngineServiceErrorCode.codeMismatch] {
            XCTAssertEqual(AuthClientError(engine: .unknown("", failure)).kind, .unknown, "\(failure)")
        }
    }

    /// A network failure reads the same whichever engine error carries it, the passkey calls' fallback included.
    ///
    /// - Given: an offline `URLError` under each engine shape of `transportFailureShapes(_:)`
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - each is `.service` with no code, the network description and suggestion, and the `URLError` itself
    ///      underneath
    func testANetworkFailureReadsTheSameUnderEveryEngineShape() {
        let offline = URLError(.notConnectedToInternet)
        for engine in Self.transportFailureShapes(offline) {
            let mapped = AuthClientError(engine: engine)
            XCTAssertEqual(mapped.kind, .service(nil), "\(engine)")
            XCTAssertEqual(mapped.errorDescription, AuthClientError.networkFailureDescription, "\(engine)")
            XCTAssertEqual(mapped.recoverySuggestion, AuthClientError.clientServiceSuggestion, "\(engine)")
            XCTAssertEqual((mapped.underlyingError as? URLError)?.code, .notConnectedToInternet, "\(engine)")
        }
    }

    /// The passkey calls' fallback over an error the client doesn't recognise asks for no bug report.
    ///
    /// - Given: the engine's error for a passkey call that failed with an error it cannot convert
    ///   (`WebAuthnError.unknown`, whose suggestion says "This should not happen" and asks for an issue)
    /// - When:
    ///    - it is mapped
    /// - Then:
    ///    - it is `.service` with no code, the engine's description, the client's network-or-service suggestion and
    ///      the engine error underneath
    func testThePasskeyFallbackAsksForNoBugReport() throws {
        #if os(iOS) || os(macOS) || os(visionOS)
        let engine = WebAuthnError.unknown(message: "Unable to list WebAuthn credentials", error: FixtureError(description: "x")).engineError
        XCTAssertTrue(engine.recoverySuggestion.hasPrefix("This should not happen."), "the engine's text changed: \(engine.recoverySuggestion)")

        let mapped = AuthClientError(engine: engine)

        XCTAssertEqual(mapped.kind, .service(nil))
        XCTAssertEqual(mapped.errorDescription, engine.errorDescription)
        XCTAssertEqual(mapped.recoverySuggestion, AuthClientError.clientServiceSuggestion)
        XCTAssertNotNil(mapped.underlyingError as? EngineAuthError)
        #else
        throw XCTSkip("WebAuthn is not available on this platform")
        #endif
    }

    /// The engine errors a transport failure `failure` reaches the client in: `.unknown` with an empty message (the
    /// sign-in flows), a code-less `.service` with the "report a bug" text (a refresh), one with empty texts (a
    /// revoke's), and the passkey calls' fallback.
    private static func transportFailureShapes(_ failure: Error) -> [EngineAuthError] {
        var shapes: [EngineAuthError] = [
            .unknown("", failure),
            .service("Service error occurred", EngineErrorMessages.reportBugToAWS(function: "authError"), failure),
            .service("", "", failure)
        ]
        #if os(iOS) || os(macOS) || os(visionOS)
        shapes.append(WebAuthnError.unknown(message: "Unable to list WebAuthn credentials", error: failure).engineError)
        #endif
        return shapes
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
        XCTAssertEqual(
            Set(AuthClientError.clientRecoverySuggestions.keys),
            Set(rows.map(\.1) + [AuthPluginErrorConstants.configurationError])
        )
        for text in AuthClientError.clientRecoverySuggestions.values {
            XCTAssertFalse(text.contains("Auth."), text)
            XCTAssertFalse(text.contains("Amplify."), text)
            XCTAssertFalse(text.contains("plugin"), text)
        }
    }

    /// The engine's configuration suggestion, which names "Auth plugin", names the client's settings instead.
    ///
    /// - Given: Cognito's `InvalidUserPoolConfigurationException` for a user pool without device tracking, and the
    ///   identity pool's `InvalidIdentityPoolConfigurationException`, each mapped by the engine to `.configuration`
    ///   with the engine's configuration suggestion
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - each is `.configuration` with Cognito's description, and a suggestion about both pools' settings and the
    ///      client's configuration that doesn't name the plugin
    func testTheConfigurationSuggestionNamesTheClient() {
        XCTAssertEqual(AuthPluginErrorConstants.configurationError, "Make sure that the amplify configuration passed to Auth plugin is valid")
        let suggestion = "Check the user pool's settings (device tracking, for the device calls), the identity pool's "
            + "settings, and the client's configuration."
        let failures: [(any EngineAuthErrorConvertible, String)] = [
            (
                AWSCognitoIdentityProvider.InvalidUserPoolConfigurationException(message: "Device tracking not currently enabled for this pool."),
                "Device tracking not currently enabled for this pool."
            ),
            (AWSCognitoIdentity.InvalidIdentityPoolConfigurationException(message: "Invalid role."), "Invalid role.")
        ]

        for (failure, description) in failures {
            let engine = failure.engineError
            XCTAssertEqual(engine.recoverySuggestion, AuthPluginErrorConstants.configurationError, description)

            let mapped = AuthClientError(engineFailure: failure)

            XCTAssertEqual(mapped.kind, .configuration, description)
            XCTAssertEqual(mapped.errorDescription, description)
            XCTAssertEqual(mapped.recoverySuggestion, suggestion, description)
            XCTAssertFalse(mapped.recoverySuggestion.contains("plugin"), description)
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
    ///    - the first is `.service` with no code, the unreadable-response description, the engine error underneath,
    ///      and the "temporary problem, retry" recovery suggestion; the contrasts keep the engine's suggestion
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
            XCTAssertEqual(description, AuthClientError.unreadableResponseDescription)
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

    /// A sign-out's revoke or global sign-out that failed in transport keeps the sign-out's context, as a network
    /// failure does: nothing retries it.
    ///
    /// - Given: the engine's revoke and global sign-out errors for a request that failed with a body that is not JSON,
    ///   URL loading's `badServerResponse`, an App Transport Security refusal, or an error the engine cannot convert
    ///   (each `.service` with empty texts, as the engine builds them); and the global sign-out's placeholder revoke
    ///   error (empty texts, nothing underneath)
    /// - When:
    ///    - each is mapped as the outcome's revoke error and global sign-out error
    /// - Then:
    ///    - each is `.service` with no code and a description that isn't empty: the unreadable-response one, or "The
    ///      service request failed."; the suggestion says the revoke, or the global sign-out, will not be retried
    ///    - the placeholder keeps its empty texts
    func testASignOutsTransportFailureSaysItIsNotRetried() {
        let rows: [(Error, String)] = [
            (NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError), AuthClientError.unreadableResponseDescription),
            (URLError(.badServerResponse), AuthClientError.unreadableResponseDescription),
            (URLError(.appTransportSecurityRequiresSecureConnection), AuthClientError.emptyServiceFailureDescription),
            (FixtureError(description: "x"), AuthClientError.emptyServiceFailureDescription)
        ]
        for (failure, description) in rows {
            let engine = EngineAuthError.service("", "", failure)
            let revoke = AuthClientError.revokeFailure(engine: engine)
            XCTAssertEqual(revoke.kind, .service(nil), "\(failure)")
            XCTAssertEqual(revoke.errorDescription, description, "\(failure)")
            XCTAssertEqual(revoke.recoverySuggestion, SignOutTexts.revokeNotRetried, "\(failure)")
            let global = AuthClientError.globalSignOutFailure(engine: engine)
            XCTAssertEqual(global.kind, .service(nil), "\(failure)")
            XCTAssertEqual(global.errorDescription, description, "\(failure)")
            XCTAssertEqual(global.recoverySuggestion, SignOutTexts.globalSignOutNotRetried, "\(failure)")
        }
        let placeholder = AuthClientError.revokeFailure(engine: .service("", "", nil))
        XCTAssertEqual(placeholder.errorDescription, "")
        XCTAssertEqual(placeholder.recoverySuggestion, "")
    }

    /// A sign-out's revoke or global sign-out that Cognito failed itself is a service error that keeps the sign-out's
    /// context, once the failure carries the exception it was made from.
    ///
    /// - Given: revoke and global sign-out failures from the user pool's `InternalErrorException` (its engine error,
    ///   with the exception as the cause), and from an error status the SDK does not model (500, then 400)
    /// - When:
    ///    - the outcome is built from them, and the internal error is also mapped without its cause
    /// - Then:
    ///    - each is `.service` with no code, the engine's description, and the suggestion that the revoke, or the
    ///      global sign-out, will not be retried
    ///    - without its cause, the internal error stays `.unknown` with the engine's text
    func testASignOutsServiceFaultSaysItIsNotRetried() {
        let internalError = AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        func unmodelled(_ status: HTTPStatusCode) -> UnknownAWSHTTPServiceError {
            UnknownAWSHTTPServiceError(
                httpResponse: HTTPResponse(body: .empty, statusCode: status),
                message: "fixture message",
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
        }
        let rows: [(String, EngineAuthError, Error)] = [
            ("internal error", internalError.engineError, internalError),
            ("500", unmodelled(.internalServerError).engineError, unmodelled(.internalServerError)),
            ("400", unmodelled(.badRequest).engineError, unmodelled(.badRequest))
        ]
        for (label, engine, cause) in rows {
            let outcome = EngineSignOutOutcome(
                revokeFailure: EngineRevokeTokenFailure(refreshToken: "refresh-token", error: engine, cause: cause),
                globalSignOutFailure: EngineGlobalSignOutFailure(accessToken: "access-token", error: engine, cause: cause)
            )
            guard case .service(nil, let revokeDescription, let revokeSuggestion, _) = outcome.revokeError,
                  case .service(nil, let globalDescription, let globalSuggestion, _) = outcome.globalSignOutError else {
                XCTFail("\(label): expected .service with no code, got \(outcome)")
                continue
            }
            XCTAssertEqual(revokeDescription, engine.errorDescription, label)
            XCTAssertEqual(revokeSuggestion, SignOutTexts.revokeNotRetried, label)
            XCTAssertEqual(globalDescription, engine.errorDescription, label)
            XCTAssertEqual(globalSuggestion, SignOutTexts.globalSignOutNotRetried, label)
        }

        let causeless = AuthClientError.revokeFailure(engine: internalError.engineError)
        XCTAssertEqual(causeless.kind, .unknown)
        XCTAssertEqual(causeless.recoverySuggestion, internalError.engineError.recoverySuggestion)
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

    /// The highest index each switch below gives. Raise it with the new case's arm.
    private static let lastSignInStepCaseIndex = 13
    private static let lastMFACaseIndex = 2
    #if os(iOS) || os(macOS) || os(visionOS)
    private static let lastFactorCaseIndex = 4
    #else
    private static let lastFactorCaseIndex = 3
    #endif
    private static let lastFlowCaseIndex = 4
    private static let lastDestinationCaseIndex = 3
    private static let lastErrorCaseIndex = 7

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
