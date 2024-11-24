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
// Test class for MFA Required scenario with Email, TOTP, and SMS MFA enabled.
// - This test suite verifies various steps in the MFA sign-in process when multiple MFA types (Email, TOTP, SMS) are required.
//   loginWith: {
//     email: true,
//   },
//   multifactor: {
//     mode: "REQUIRED",
//     sms: true,
//     totp: true,
//     email: true, (email has not been added to backend at the time of writing this test)
//   },
class EmailMFAWithAllMFATypesRequiredTests: AWSAuthBaseTest {

    // Sets up the test environment using Gen2 configuration and adds required plugins
    override func setUp() async throws {
        // Only run these tests with Gen2 configuration
        onlyUseGen2Configuration = true

        // Specify a custom test configuration for these tests
        amplifyOutputsFile = "testconfiguration/AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs"

        // Add API plugin to Amplify
        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)
        try await super.setUp()

        // Clear session to ensure a fresh state for each test
        AuthSessionHelper.clearSession()
    }

    // Tear down test environment and clear the session
    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test the sign-in flow when MFA setup is required with multiple MFA options (Email and TOTP).
    ///
    /// - Given: The user has successfully signed up and is trying to sign in.
    /// - When: The user provides valid username and password.
    /// - Then: The sign-in process should return a `.continueSignInWithMFASetupSelection` challenge to select the MFA type to set up.
    func testSuccessfulMFASetupSelectionStep() async {

        let options = AuthSignInRequest.Options()

        do {
            // Step 1: Sign up a new user
            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            // Step 2: Attempt to sign in with the newly created user
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)

            // Step 3: Ensure that MFA setup is required and TOTP and Email are available as options
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Expected .continueSignInWithMFASetupSelection step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp), "TOTP should be available as an MFA option")
            XCTAssertTrue(mfaTypes.contains(.email), "Email should be available as an MFA option")
            XCTAssertFalse(mfaTypes.contains(.sms), "SMS should not be available as an MFA option")
            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test the sign-in flow with Email MFA when the user is prompted to confirm the MFA code.
    ///
    /// - Given: The user is required to provide an Email MFA code to complete sign-in.
    /// - When: The user provides valid username and password, and then submits the correct MFA code.
    /// - Then: The sign-in should complete after confirming the MFA code.
    func testSuccessfulEmailMFACodeStep() async {
        do {
            // Step 1: Set up a subscription to receive MFA codes
            await subscribeToOTPCreation()
            let uniqueId = UUID().uuidString
            let username = randomEmail
            let password = "Pp123@\(uniqueId)"

            // Step 2: Sign up a new user with email
            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password,
                email: username)

            // Step 3: Attempt to sign in, which should prompt for Email MFA
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options())

            // Step 4: Verify that the next step is to confirm the Email MFA code
            guard case .confirmSignInWithOTP(let codeDetails) = result.nextStep else {
                XCTFail("Expected .confirmSignInWithOTP step, got \(result.nextStep)")
                return
            }
            if case .email(let destination) = codeDetails.destination {
                XCTAssertNotNil(destination, "Email destination should be provided")
            } else {
                XCTFail("Destination should be email")
            }
            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 5: Retrieve the MFA code and confirm the sign-in
            guard let mfaCode = try await otp(for: username.lowercased()) else {
                XCTFail("Failed to retrieve the MFA code")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: mfaCode,
                options: .init())

            // Step 6: Ensure that the sign-in is complete
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Expected .done step after confirming MFA")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "User should be signed in at this stage")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test confirming sign-in for Email MFA setup after selecting it as an MFA option.
    ///
    /// - Given: The user is prompted to select Email as an MFA type.
    /// - When: The user selects Email and submits their email address for setup.
    /// - Then: The user should be prompted to confirm the Email MFA code and complete sign-in.
    func testConfirmSignInForEmailMFASetupSelectionStep() async {
        do {
            // Step 1: Set up a subscription to receive MFA codes
            await subscribeToOTPCreation()
            let uniqueId = UUID().uuidString
            let username = "\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            // Step 2: Sign up a new user
            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            // Step 3: Initiate sign-in, expecting MFA setup selection
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options())

            // Step 4: Verify that the next step is to select an MFA type
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Expected .continueSignInWithMFASetupSelection step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp), "TOTP should be available as an MFA option")
            XCTAssertTrue(mfaTypes.contains(.email), "Email should be available as an MFA option")
            XCTAssertFalse(mfaTypes.contains(.sms), "SMS should not be available as an MFA option")
            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 5: Select Email as the MFA option to proceed
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: MFAType.email.challengeResponse)

            // Step 6: Verify that the next step is to set up Email MFA
            guard case .continueSignInWithEmailMFASetup = confirmSignInResult.nextStep else {
                XCTFail("Expected .continueSignInWithEmailMFASetup step")
                return
            }

            // Step 7: Provide the email address to complete the setup
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: defaultTestEmail)

            // Step 8: Verify that the next step is to confirm the Email MFA code
            guard case .confirmSignInWithOTP(let deliveryDetails) = confirmSignInResult.nextStep else {
                XCTFail("Expected .confirmSignInWithOTP step")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertNotNil(destination, "Email destination should be provided")
            }

            XCTAssertFalse(result.isSignedIn, "User should not be signed in at this stage")

            // Step 9: Confirm the sign-in with the received MFA code
            guard let mfaCode = try await otp(for: username.lowercased()) else {
                XCTFail("Failed to retrieve the MFA code")
                return
            }
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: mfaCode,
                options: .init())
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Expected .done step after confirming MFA")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "User should be signed in at this stage")

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test a signIn with valid inputs getting continueSignInWithMFASetupSelection challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithMFASetupSelection response
    ///
    func testConfirmSignInForTOTPMFASetupSelectionStep() async {
        do {

            let uniqueId = UUID().uuidString
            let username = "\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            // Step 1: initiate sign in
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options())
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithMFASetupSelection for next step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp))
            XCTAssertTrue(mfaTypes.contains(.email))
            XCTAssertFalse(mfaTypes.contains(.sms))
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // Step 2: continue sign in by selecting TOTP for set up
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: MFAType.totp.challengeResponse)
            guard case .continueSignInWithTOTPSetup(let totpDetails) = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }
            XCTAssertNotNil(totpDetails.sharedSecret)
            XCTAssertNotNil(totpDetails.username)
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // Step 3: complete sign in by verifying TOTP set up
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpDetails.sharedSecret)
            let pluginOptions = AWSAuthConfirmSignInOptions(friendlyDeviceName: "device")
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: totpCode,
                options: .init(pluginOptions: pluginOptions))
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Expected .done step after confirming MFA")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "User should be signed in at this stage")

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}
