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

// Test class for scenarios where only Email MFA is required.
// - This test suite verifies the sign-in process when only Email MFA is enabled.
class EmailMFARequiredTests: AWSAuthBaseTest {

    // Sets up the test environment with a custom configuration and adds required plugins
    override func setUp() async throws {
        // Only run these tests with Gen2 configuration
        onlyUseGen2Configuration = true

        // Specify a custom test configuration for these tests
        amplifyOutputsFile = "testconfiguration/AWSCognitoEmailMFARequiredTests-amplify_outputs"

        // Add API plugin to Amplify
        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)
        try await super.setUp()

        // Clear session to ensure a fresh state for each test
        AuthSessionHelper.clearSession()
    }

    // Tear down the test environment and clear the session
    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test the sign-in flow when Email MFA setup is required.
    ///
    /// - Given: A new user is created, and only Email MFA is required for the account.
    /// - When: The user provides valid username and password, and then proceeds through the MFA setup flow.
    /// - Then: The user should successfully complete the MFA setup and be able to sign in.
    ///
    /// - MFA Setup Flow:
    ///     - Step 1: User signs in and receives the `continueSignInWithEmailMFASetup` challenge.
    ///     - Step 2: User provides their email for MFA setup.
    ///     - Step 3: User receives and confirms the MFA code sent to their email.
    ///     - Step 4: Sign-in completes, and the email is associated with the user account.
    func testSuccessfulEmailMFASetupStep() async {
        do {
            // Step 1: Set up a subscription to receive MFA codes
            createMFASubscription()

            // Step 2: Sign up a new user
            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            let options = AuthSignInRequest.Options()
            // Step 3: Initiate sign-in, expecting MFA setup to be required
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)

            // Step 4: Ensure that the next step is to set up Email MFA
            guard case .continueSignInWithEmailMFASetup = result.nextStep else {
                XCTFail("Expected .continueSignInWithEmailMFASetup step, got \(result.nextStep)")
                return
            }

            // Step 5: Provide the email address to complete MFA setup
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: username + "@integTest.com")

            // Step 6: Ensure that the next step is to confirm the Email MFA code
            guard case .confirmSignInWithEmailMFACode(let deliveryDetails) = confirmSignInResult.nextStep else {
                XCTFail("Expected .confirmSignInWithEmailMFACode step, got \(confirmSignInResult.nextStep)")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertNotNil(destination, "Email destination should be provided")
            } else {
                XCTFail("Expected the destination to be email")
            }

            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 7: Retrieve the MFA code sent to the email and confirm the sign-in
            guard let mfaCode = try await waitForMFACode(for: username.lowercased()) else {
                XCTFail("Failed to retrieve the MFA code")
                return
            }

            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: mfaCode,
                options: .init())

            // Step 8: Ensure that the sign-in process is complete
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Expected .done step after confirming MFA")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "User should be signed in at this stage")
            XCTAssertFalse(result.isSignedIn, "User should not be signed in at the initial stage")

            // Step 9: Verify that the email is associated with the user account
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            XCTAssertEqual(attributes.first(where: { $0.key == .email })?.value, username + "@integTest.com")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
