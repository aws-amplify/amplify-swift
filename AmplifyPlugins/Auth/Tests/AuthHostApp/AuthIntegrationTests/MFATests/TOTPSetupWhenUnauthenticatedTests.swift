//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin

class TOTPSetupWhenUnauthenticatedTests: AWSAuthBaseTest {

    override func setUp() async throws {
        // Use a custom configuration these tests
        amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration"
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test successful next step continueSignInWithTOTPSetup
    ///
    /// - Given: A newly signed up user in Cognito user pool with REQUIRED MFA, No Phone Number Added
    ///
    /// - When:
    ///    - I invoke signIn API
    /// - Then:
    ///    - I should get continueSignInWithTOTPSetup Step for signIn call and can be successfully confirmed
    ///
    func testSignForSetupMFANextStep() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup should succeed")

        // WHEN

        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .continueSignInWithTOTPSetup(let totpSetupDetails) = result.nextStep else {
                XCTFail("Next step should be continueSignInWithTOTPSetup")
                return
            }
            XCTAssertNotNil(totpSetupDetails.sharedSecret)
        } catch {
            XCTFail("SignIn with invalid auth flow should not succeed. \(error)")
        }
    }
}
