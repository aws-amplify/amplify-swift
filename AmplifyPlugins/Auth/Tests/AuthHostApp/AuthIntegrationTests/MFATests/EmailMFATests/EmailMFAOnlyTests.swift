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

// Follow MFATests/EmailMFAOnlyTests/Readme.md for test setup locally
// Test class for scenarios where only Email MFA is required.
// - This test suite verifies the sign-in process when only Email MFA is enabled.
//   loginWith: {
//     email: true,
//   },
//   multifactor: {
//     mode: "REQUIRED",
//     sms: true,
//     email: true, (email has not been added to backend at the time of writing this test)
//   },
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
            await subscribeToOTPCreation()

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
                challengeResponse: defaultTestEmail)

            // Step 6: Ensure that the next step is to confirm the Email MFA code
            guard case .confirmSignInWithOTP(let deliveryDetails) = confirmSignInResult.nextStep else {
                XCTFail("Expected .confirmSignInWithOTP step, got \(confirmSignInResult.nextStep)")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertNotNil(destination, "Email destination should be provided")
            } else {
                XCTFail("Expected the destination to be email")
            }

            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 7: Retrieve the MFA code sent to the email and confirm the sign-in
            guard let mfaCode = try await otp(for: username.lowercased()) else {
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
            XCTAssertEqual(attributes.first(where: { $0.key == .email })?.value, defaultTestEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    /// Test the sign-in flow when an incorrect MFA code is entered first, followed by the correct MFA code.
    ///
    /// - Given: A new user is created, and only Email MFA is required for the account.
    /// - When: The user provides valid username and password, receives the MFA code via email, enters an incorrect code,
    ///         and then enters the correct MFA code.
    /// - Then: The user should receive a `codeMismatch` error for the incorrect code, but after entering the correct MFA code,
    ///         they should successfully complete the MFA process and sign in.
    ///
    /// - MFA Setup Flow:
    ///     - Step 1: User signs in and receives the `confirmSignInWithOTP` challenge.
    ///     - Step 2: User enters an incorrect MFA code and receives a `codeMismatch` error.
    ///     - Step 3: User enters the correct MFA code.
    ///     - Step 4: Sign-in completes, and the email is associated with the user account.
    func testSuccessfulEmailMFAWithIncorrectCodeFirstAndThenValidOne() async {
        do {
            // Step 1: Set up a subscription to receive MFA codes
            await subscribeToOTPCreation()

            // Step 2: Sign up a new user
            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password,
                email: defaultTestEmail)

            let options = AuthSignInRequest.Options()

            // Step 3: Initiate sign-in, expecting MFA setup to be required
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)

            // Step 6: Ensure that the next step is to confirm the Email MFA code
            guard case .confirmSignInWithOTP(let deliveryDetails) = result.nextStep else {
                XCTFail("Expected .confirmSignInWithOTP step, got \(result.nextStep)")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertNotNil(destination, "Email destination should be provided")
            } else {
                XCTFail("Expected the destination to be email")
            }

            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 7: Retrieve the MFA code sent to the email and confirm the sign-in
            guard let mfaCode = try await otp(for: username.lowercased()) else {
                XCTFail("Failed to retrieve the MFA code")
                return
            }

            // Step 6: Enter an incorrect MFA code first
            do {
                _ = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: "000000",
                    options: .init())
            } catch AuthError.service(_, _, let error) {

                guard let underlyingError = error as? AWSCognitoAuthError else {
                    XCTFail("Expected an AWS Cognito Auth error")
                    return
                }
                guard underlyingError == .codeMismatch else {
                    XCTFail("Expected .codeMismatch error")
                    return
                }

                // Step 7: Enter the correct MFA code
                let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: mfaCode,
                    options: .init())

                // Step 8: Ensure that the sign-in process is complete
                guard case .done = confirmSignInResult.nextStep else {
                    XCTFail("Expected .done step after confirming MFA")
                    return
                }
                XCTAssertTrue(confirmSignInResult.isSignedIn, "User should be signed in at this stage")
                XCTAssertFalse(result.isSignedIn, "User should not be signed in at the initial stage")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
