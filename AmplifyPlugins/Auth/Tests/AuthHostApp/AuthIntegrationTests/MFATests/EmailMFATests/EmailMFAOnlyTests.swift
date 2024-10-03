//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

// MFA Required
//  - Email
class EmailMFARequiredTests: AWSAuthBaseTest {

    override func setUp() async throws {
        onlyUseGen2Configuration = true
        // Use a custom configuration these tests
        amplifyOutputsFile = "testconfiguration/AWSCognitoEmailMFARequiredTests-amplify_outputs"

        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test a signIn with valid inputs getting continueSignInWithEmailMFASetup challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithEmailMFASetup response
    /// - When:
    ///    - I invoke confirm signIn with valid values,
    /// - Then:
    ///    - With series of challenges, sign in should succeed
    //Requires only Email MFA to be enabled
    func testSuccessfulEmailMFASetupStep() async {

        do {
            createMFASubscription()

            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"
            
            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            let options = AuthSignInRequest.Options()
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)

            guard case .continueSignInWithEmailMFASetup = result.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup for next step, instead got: \(result.nextStep)")
                return
            }

            // Step 2: pass an email to setup
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: username + "@integTest.com")
            guard case .confirmSignInWithEmailMFACode(let deliveryDetails) = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertNotNil(destination)
            } else {
                XCTFail("Destination should be email")
            }

            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // step 3: confirm sign in
            guard let mfaCode = try await waitForMFACode(for: username.lowercased()) else {
                XCTFail("failed to retrieve the mfa code")
                return
            }
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: mfaCode,
                options: .init())
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // email should get added to the account
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            XCTAssertEqual(attributes.first(where: { $0.key == .email})?.value, username + "@integTest.com")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
}
