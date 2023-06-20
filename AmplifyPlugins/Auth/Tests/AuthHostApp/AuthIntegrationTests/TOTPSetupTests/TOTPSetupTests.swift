//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

class TOTPSetupTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
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
    func testSuccessfulSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")

        do {
            let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
        // Clean up user
        try await Amplify.Auth.deleteUser()
    }

}
