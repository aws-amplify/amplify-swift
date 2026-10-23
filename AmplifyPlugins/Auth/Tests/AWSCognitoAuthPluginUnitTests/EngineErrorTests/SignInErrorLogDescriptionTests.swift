//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The TOTP setup actions (`SetUpTOTP`, `VerifyTOTPSetup`, `CompleteTOTPSetup`) log a `SignInError`'s
/// description. They read it from `engineError` now, where they read it from the plugin's `authError`
/// before. The logged line must not change, so each description is checked against the
/// string the plugin's `SignInError.authError` gave before the engine move, written out here: `authError` is
/// now built from `engineError`, so comparing the two would not catch a drift.
final class SignInErrorLogDescriptionTests: XCTestCase {

    struct SentinelError: Error {}

    /// Test that the engine error's description is the one the plugin logged before the engine move
    ///
    /// - Given: A `SignInError` of every case, and `.service` over an engine error (standing in for the SDK
    ///   errors the plugin converted), a `SignInError` and two unrelated errors
    /// - When:
    ///    - `errorDescription` is read through `engineError`, as the TOTP setup actions log it, and through
    ///      `authError`
    /// - Then:
    ///    - Both are the string the plugin's `authError` gave before the engine move
    ///
    func testEngineErrorDescriptionMatchesThePluginsLoggedDescription() {
        let usernameRequired = "Username is required to signIn"
        // `AuthError.unknown`'s description prefixes its message.
        let unknown = "Unexpected error occurred with message: "
        let expectations: [(SignInError, String)] = [
            (.configuration(message: "configuration message"), "configuration message"),
            (.service(error: SentinelError()), unknown),
            (.service(error: NSError(domain: "domain", code: 7)), unknown),
            (.service(error: EngineAuthError.service("service description", "recovery", nil)), "service description"),
            (.service(error: SignInError.inputValidation(field: "nested")), usernameRequired),
            (.inputValidation(field: "username"), usernameRequired),
            (.invalidServiceResponse(message: "invalid response"), "invalid response"),
            (.calculation(.calculation), unknown + "SignIn calculation returned an error"),
            (.calculation(.numberConversion), unknown + "SignIn calculation returned an error"),
            (.calculation(.illegalParameter), unknown + "SignIn calculation returned an error"),
            (.hostedUI(.signInURI), "SignIn URI could not be created"),
            (.hostedUI(.tokenURI), "Token URI could not be created"),
            (.hostedUI(.signOutURI), "SignOut URI could not be created"),
            (
                .webAuthn(.unknown(message: "webauthn message")),
                "An unknown error type was thrown by the service. webauthn message."
            ),
            (.unknown(message: "unknown message"), unknown + "unknown message")
        ]
        for (error, expected) in expectations {
            XCTAssertEqual(error.engineError.errorDescription, expected, String(describing: error))
            XCTAssertEqual(error.authError.errorDescription, expected, String(describing: error))
        }
    }
}
