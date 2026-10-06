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
/// before. The logged line must not change.
final class SignInErrorLogDescriptionTests: XCTestCase {

    struct SentinelError: Error {}

    /// Test that the engine error's description is the one the plugin error printed
    ///
    /// - Given: A `SignInError` of every case, and `.service` over an SDK-convertible, an engine and an
    ///   unrelated error
    /// - When:
    ///    - `errorDescription` is read through `engineError` and through `authError`
    /// - Then:
    ///    - Both give the same string
    ///
    func testEngineErrorDescriptionMatchesAuthErrorDescription() {
        let errors: [SignInError] = [
            .configuration(message: "configuration message"),
            .service(error: SentinelError()),
            .service(error: NSError(domain: "domain", code: 7)),
            .service(error: EngineAuthError.service("service description", "recovery", nil)),
            .service(error: SignInError.inputValidation(field: "nested")),
            .inputValidation(field: "username"),
            .invalidServiceResponse(message: "invalid response"),
            .calculation(.calculation),
            .calculation(.numberConversion),
            .calculation(.illegalParameter),
            .hostedUI(.signInURI),
            .hostedUI(.tokenURI),
            .hostedUI(.signOutURI),
            .webAuthn(.unknown(message: "webauthn message")),
            .unknown(message: "unknown message")
        ]
        for error in errors {
            XCTAssertEqual(
                error.engineError.errorDescription,
                error.authError.errorDescription,
                String(describing: error)
            )
        }
    }
}
