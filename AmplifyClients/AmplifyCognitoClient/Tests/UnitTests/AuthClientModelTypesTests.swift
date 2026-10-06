//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class AuthClientModelTypesTests: XCTestCase {

    // MARK: - AuthClientUser

    /// - Given: two users built from the same username and `sub`
    /// - When: they are compared and hashed
    /// - Then:
    ///    - they are equal, hash alike, and collapse to one element in a `Set`
    func testUserEqualAndHashesAlikeWhenBothFieldsMatch() {
        let first = AuthClientUser(username: "alice", userId: "sub-1")
        let second = AuthClientUser(username: "alice", userId: "sub-1")

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.hashValue, second.hashValue)
        XCTAssertEqual(Set([first, second]).count, 1)
    }

    /// Two sessions can hold the same username against different pools, and a user can be renamed,
    /// so neither field alone identifies the user.
    ///
    /// - Given: users differing only in `username`, and users differing only in `userId`
    /// - When: they are compared
    /// - Then:
    ///    - each pair is unequal, and a `Set` keeps all three
    func testUserUnequalWhenEitherFieldDiffers() {
        let base = AuthClientUser(username: "alice", userId: "sub-1")
        let renamed = AuthClientUser(username: "alice2", userId: "sub-1")
        let otherSub = AuthClientUser(username: "alice", userId: "sub-2")

        XCTAssertNotEqual(base, renamed)
        XCTAssertNotEqual(base, otherSub)
        XCTAssertEqual(Set([base, renamed, otherSub]).count, 3)
    }

    /// - Given: a user built with the memberwise initialiser
    /// - When: its properties are read
    /// - Then:
    ///    - `username` and `userId` are the values passed in
    func testUserExposesItsFields() {
        let user = AuthClientUser(username: "bob", userId: "3f1c")
        XCTAssertEqual(user.username, "bob")
        XCTAssertEqual(user.userId, "3f1c")
    }

    // MARK: - AuthClientUserAttributeKey

    /// `custom` and `unknown` both carry a string, so equality has to look at the case as well as
    /// the payload.
    ///
    /// - Given: `custom("x")`, `unknown("x")`, `custom("y")` and a second `custom("x")`
    /// - When: they are compared and put in a `Set`
    /// - Then:
    ///    - only the two `custom("x")` values are equal, and the `Set` holds three
    func testAttributeKeyEqualityIsCaseAndPayloadAware() {
        XCTAssertEqual(AuthClientUserAttributeKey.custom("x"), .custom("x"))
        XCTAssertNotEqual(AuthClientUserAttributeKey.custom("x"), .unknown("x"))
        XCTAssertNotEqual(AuthClientUserAttributeKey.custom("x"), .custom("y"))
        XCTAssertNotEqual(AuthClientUserAttributeKey.email, .emailVerified)

        let keys: Set<AuthClientUserAttributeKey> = [.custom("x"), .unknown("x"), .custom("y"), .custom("x")]
        XCTAssertEqual(keys.count, 3)
    }

    // MARK: - AuthClientDeliveryDestination and AuthClientCodeDeliveryDetails

    /// - Given: destinations with the same string in different cases, and the same case with and
    ///   without a string
    /// - When: they are compared
    /// - Then:
    ///    - only identical case-and-payload pairs are equal
    func testDeliveryDestinationEqualityIsCaseAndPayloadAware() {
        XCTAssertEqual(AuthClientDeliveryDestination.email("a***@example.com"), .email("a***@example.com"))
        XCTAssertEqual(AuthClientDeliveryDestination.unknown(nil), .unknown(nil))
        XCTAssertNotEqual(AuthClientDeliveryDestination.sms("+1***"), .phone("+1***"))
        XCTAssertNotEqual(AuthClientDeliveryDestination.email(nil), .email("a***@example.com"))
    }

    /// - Given: code delivery details built with and without an attribute key
    /// - When: they are compared
    /// - Then:
    ///    - `attributeKey` defaults to `nil`, and both fields take part in equality
    func testCodeDeliveryDetailsEqualityUsesBothFields() {
        let bare = AuthClientCodeDeliveryDetails(destination: .email("a***"))
        XCTAssertNil(bare.attributeKey)
        XCTAssertEqual(bare, AuthClientCodeDeliveryDetails(destination: .email("a***"), attributeKey: nil))
        XCTAssertNotEqual(bare, AuthClientCodeDeliveryDetails(destination: .email("a***"), attributeKey: .email))
        XCTAssertNotEqual(bare, AuthClientCodeDeliveryDetails(destination: .sms("a***")))
    }

    // MARK: - AuthClientTOTPSetupDetails

    /// - Given: TOTP setup details differing in secret or username
    /// - When: they are compared
    /// - Then:
    ///    - only details with both fields equal are equal
    func testTOTPSetupDetailsEqualityUsesBothFields() {
        let details = AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: "alice")
        XCTAssertEqual(details, AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: "alice"))
        XCTAssertNotEqual(details, AuthClientTOTPSetupDetails(sharedSecret: "OTHER", username: "alice"))
        XCTAssertNotEqual(details, AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: "bob"))
    }

    /// The shared secret never reaches text: stricter than the plugin's `TOTPSetupDetails`, which is not
    /// redacted.
    ///
    /// - Given: TOTP setup details, alone and inside `continueSignInWithTOTPSetup` and a sign-in result
    /// - When: each is rendered by interpolation, `String(describing:)`, `String(reflecting:)`, `print`,
    ///   `debugPrint` and `dump`, and read through its mirror
    /// - Then:
    ///    - no rendering contains the secret, each says `<redacted>`, and the username is kept
    func testTOTPSetupDetailsRedactTheSecretInEveryRendering() {
        let secret = "JBSWY3DPEHPK3PXP"
        let details = AuthClientTOTPSetupDetails(sharedSecret: secret, username: "alice")
        let step = AuthClientSignInStep.continueSignInWithTOTPSetup(details)
        let result = AuthClientSignInResult(nextStep: step)
        let values: [(String, Any)] = [("details", details), ("step", step), ("result", result)]

        for (name, value) in values {
            var printed = ""
            print(value, to: &printed)
            var debugPrinted = ""
            debugPrint(value, to: &debugPrinted)
            var dumped = ""
            dump(value, to: &dumped)
            let renderings = [
                ("interpolation", "\(value)"),
                ("describing", String(describing: value)),
                ("reflecting", String(reflecting: value)),
                ("print", printed),
                ("debugPrint", debugPrinted),
                ("dump", dumped)
            ]
            for (form, text) in renderings {
                XCTAssertFalse(text.contains(secret), "\(name), \(form): the secret is rendered")
                XCTAssertTrue(text.contains("<redacted>"), "\(name), \(form): no redaction marker")
                XCTAssertTrue(text.contains("alice"), "\(name), \(form): the username is kept")
            }
        }
        let children = Mirror(reflecting: details).children
        XCTAssertFalse(children.contains { secret == "\($0.value)" }, "the mirror holds the secret")
        XCTAssertEqual(details.sharedSecret, secret, "the property itself is unchanged")
    }

    /// The URI format is copied from Amplify core's `TOTPSetupDetails.getSetupURI`, so an app
    /// moving from the plugin to the client gets the same URI for the same inputs.
    ///
    /// - Given: TOTP setup details for `alice`
    /// - When: `getSetupURI` is called with and without an account name
    /// - Then:
    ///    - the URI is `otpauth://totp/<app>:<account>?secret=<secret>&issuer=<app>`, and the
    ///      account falls back to the username
    func testTOTPSetupURIMatchesAmplifyFormat() throws {
        let details = AuthClientTOTPSetupDetails(sharedSecret: "JBSWY3DPEHPK3PXP", username: "alice")

        XCTAssertEqual(
            try details.getSetupURI(appName: "MyApp").absoluteString,
            "otpauth://totp/MyApp:alice?secret=JBSWY3DPEHPK3PXP&issuer=MyApp"
        )
        XCTAssertEqual(
            try details.getSetupURI(appName: "MyApp", accountName: "work").absoluteString,
            "otpauth://totp/MyApp:work?secret=JBSWY3DPEHPK3PXP&issuer=MyApp"
        )
    }

    /// `getSetupURI` throws `validation` when `URL(string:)` refuses the input. Modern Foundation
    /// percent-encodes rather than refusing, so this checks the error the method throws rather
    /// than trying to provoke it.
    ///
    /// - Given: a `validation` error built as `getSetupURI` builds it
    /// - When: its `AmplifyError` members are read
    /// - Then:
    ///    - the field, description, suggestion and underlying error come back as passed in
    func testValidationErrorExposesItsPayload() {
        let underlying = AuthClientError.unknown("inner", "retry")
        let error = AuthClientError.validation(field: "appName", "bad", "fix it", underlying)

        guard case .validation(let field, _, _, _) = error else {
            return XCTFail("Expected validation, got \(error)")
        }
        XCTAssertEqual(field, "appName")
        XCTAssertEqual(error.errorDescription, "bad")
        XCTAssertEqual(error.recoverySuggestion, "fix it")
        XCTAssertEqual((error.underlyingError as? AuthClientError)?.errorDescription, "inner")
    }

    // MARK: - Raw values

    /// The raw values are Amplify core's, which are the implicit case names. (The plugin module
    /// redefines `rawValue` as the Cognito challenge string; that is a plugin extension, not core.)
    ///
    /// - Given: every `AuthClientMFAType` and `AuthClientFactorType` case
    /// - When: its raw value is read and fed back to `init(rawValue:)`
    /// - Then:
    ///    - the raw values match Amplify core's and round-trip
    func testRawValuesMatchAmplifyCore() {
        let mfa: [(AuthClientMFAType, String)] = [(.sms, "sms"), (.totp, "totp"), (.email, "email")]
        for (type, raw) in mfa {
            XCTAssertEqual(type.rawValue, raw)
            XCTAssertEqual(AuthClientMFAType(rawValue: raw), type)
        }

        var factors: [(AuthClientFactorType, String)] = [
            (.password, "password"), (.passwordSRP, "passwordSRP"), (.smsOTP, "smsOTP"), (.emailOTP, "emailOTP")
        ]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            factors.append((.webAuthn, "webAuthn"))
        }
        #endif
        for (type, raw) in factors {
            XCTAssertEqual(type.rawValue, raw)
            XCTAssertEqual(AuthClientFactorType(rawValue: raw), type)
        }
    }

    /// Each MFA type names the Cognito string an MFA selection answers with, as the plugin's
    /// `MFAType.challengeResponse` does, and that string passes the client's own selection check.
    /// (An MFA setup selection is not checked before it is sent, as in the plugin, so there is nothing
    /// to assert there.)
    ///
    /// - Given: every `AuthClientMFAType` case
    /// - When:
    ///    - its `challengeResponse` is read
    ///    - and checked as the answer to an MFA selection
    /// - Then:
    ///    - it is `SMS_MFA`, `SOFTWARE_TOKEN_MFA` or `EMAIL_OTP`, and `rawValue` is still core's
    ///    - the check accepts it, and refuses `rawValue`
    ///
    func testChallengeResponseIsTheCognitoMFAName() throws {
        let expected: [(AuthClientMFAType, String)] = [(.sms, "SMS_MFA"), (.totp, "SOFTWARE_TOKEN_MFA"), (.email, "EMAIL_OTP")]
        let all: Set<AuthClientMFAType> = [.sms, .totp, .email]
        for (type, response) in expected {
            XCTAssertEqual(type.challengeResponse, response)
            XCTAssertNotEqual(type.rawValue, response)
            XCTAssertNoThrow(try SessionCore.validate(type.challengeResponse, for: .continueSignInWithMFASelection(all)))
        }
        XCTAssertThrowsError(try SessionCore.validate(AuthClientMFAType.totp.rawValue, for: .continueSignInWithMFASelection(all)))
    }

    // MARK: - AuthClientSignInStep equality

    /// Amplify core's `AuthSignInStep` synthesises `Equatable`, so equality looks at payloads. The
    /// mirror must do the same, or `AuthSessionState.awaitingChallenge` would treat two different
    /// challenges as one.
    ///
    /// - Given: pairs of sign-in steps that share a case but differ in payload
    /// - When: they are compared
    /// - Then:
    ///    - each pair is unequal, while identical steps are equal
    func testSignInStepEqualityIsPayloadAware() {
        let email = AuthClientCodeDeliveryDetails(destination: .email("a***"))
        let sms = AuthClientCodeDeliveryDetails(destination: .sms("+1***"))

        XCTAssertEqual(AuthClientSignInStep.confirmSignInWithOTP(email), .confirmSignInWithOTP(email))
        XCTAssertNotEqual(AuthClientSignInStep.confirmSignInWithOTP(email), .confirmSignInWithOTP(sms))
        XCTAssertNotEqual(
            AuthClientSignInStep.confirmSignInWithSMSMFACode(sms, nil),
            .confirmSignInWithSMSMFACode(sms, ["k": "v"])
        )
        XCTAssertNotEqual(
            AuthClientSignInStep.continueSignInWithMFASelection([.sms, .totp]),
            .continueSignInWithMFASelection([.totp])
        )
        XCTAssertEqual(
            AuthClientSignInStep.continueSignInWithMFASelection([.sms, .totp]),
            .continueSignInWithMFASelection([.totp, .sms])
        )
        XCTAssertNotEqual(
            AuthClientSignInStep.continueSignInWithMFASelection([.totp]),
            .continueSignInWithMFASetupSelection([.totp])
        )
        XCTAssertNotEqual(
            AuthClientSignInStep.continueSignInWithTOTPSetup(.init(sharedSecret: "a", username: "u")),
            .continueSignInWithTOTPSetup(.init(sharedSecret: "b", username: "u"))
        )
        XCTAssertNotEqual(
            AuthClientSignInStep.continueSignInWithFirstFactorSelection([.password]),
            .continueSignInWithFirstFactorSelection([.password, .emailOTP])
        )
        XCTAssertNotEqual(AuthClientSignInStep.resetPassword(nil), .confirmSignUp(nil))
        XCTAssertNotEqual(AuthClientSignInStep.confirmSignInWithPassword, .confirmSignInWithTOTPCode)
        XCTAssertEqual(AuthClientSignInStep.done, .done)
    }
}
