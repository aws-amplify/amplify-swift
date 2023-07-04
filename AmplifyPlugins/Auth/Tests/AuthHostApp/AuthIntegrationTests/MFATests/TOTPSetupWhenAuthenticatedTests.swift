//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin

class TOTPSetupWhenAuthenticatedTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")
    }

    override func tearDown() async throws {
        // Clean up user
        try await Amplify.Auth.deleteUser()
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A signed in user  in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.setUpTOTP and verifyTOTPSetup API's
    /// - Then:
    ///    - I should not get any errors and all the API's should be a success
    ///
    func testSuccessfulTOTPSetupWhileAuthenticated() async throws {

        do {
            let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
        } catch {
            XCTFail("API should succeed without any errors instead failed with \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A signed in user  in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.setUpTOTP
    ///    - And verifyTOTPSetup API with incorrect code
    ///   Then:
    ///    - I should get an exception about the code mismatch
    ///   Then:
    ///    - I verifyTOTPSetup API again with the correct code
    /// - Then:
    ///    - I should not get any errors and all the API's should be a success
    ///
    func testSuccessfulTOTPSetupWithInitialError() async throws {

        var totpSetupDetails: TOTPSetupDetails?
        do {
            totpSetupDetails = try await Amplify.Auth.setUpTOTP()

            try await Amplify.Auth.verifyTOTPSetup(code: "123456")
            XCTFail("Should not succeed with incorrect TOTP Code")
        } catch {

            guard let authError = error as? AuthError,
                  case .service(_, _, let underlyingError) = authError else {
                XCTFail("Should throw service error")
                return
            }

            guard case .softwareTokenMFANotEnabled = underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should throw softwareTokenMFANotEnabled error.")
                return
            }

            do {
                let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails!.sharedSecret)
                try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
            } catch {
                XCTFail("API should succeed without any errors instead failed with \(error)")
            }
        }
    }

}
