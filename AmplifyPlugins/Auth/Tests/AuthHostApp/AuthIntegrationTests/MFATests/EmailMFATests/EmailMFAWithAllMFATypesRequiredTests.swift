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
//  - TOTP
//  - SMS
class EmailMFAWithAllMFATypesRequiredTests: AWSAuthBaseTest {

    override func setUp() async throws {
        // run these tests only with Gen2
        onlyUseGen2Configuration = true
        // Use a custom configuration these tests
        amplifyOutputsFile = "testconfiguration/AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs"

        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
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
    func testSuccessfulMFASetupSelectionStep() async {

        let options = AuthSignInRequest.Options()

        do {
            let uniqueId = UUID().uuidString
            let username = "integTest\(uniqueId)"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password)

            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: options)
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithMFASetupSelection for next step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp))
            XCTAssertTrue(mfaTypes.contains(.email))
            XCTAssertFalse(mfaTypes.contains(.sms))
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a signIn with valid inputs getting confirmSignInWithEmailMFACode challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .confirmSignInWithEmailMFACode response
    ///
    func testSuccessfulEmailMFACodeStep() async {

        do {
            createMFASubscription()
            let uniqueId = UUID().uuidString
            let username = "\(uniqueId)@integTest.com"
            let password = "Pp123@\(uniqueId)"

            _ = try await AuthSignInHelper.signUpUserReturningResult(
                username: username,
                password: password,
                email: username)

            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options())

            guard case .confirmSignInWithEmailMFACode(let codeDetails) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithEmailMFACode for next step, instead got: \(result.nextStep)")
                return
            }
            if case .email(let destination) = codeDetails.destination {
                XCTAssertNotNil(destination)
            } else {
                XCTFail("Destination should be email")
            }
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // step 2: confirm sign in
            guard let mfaCode = try await waitForMFACode(for: username.lowercased()) else {
                XCTFail("failed to retrieve the mfa code")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: mfaCode,
                options: .init())
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
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
    func testConfirmSignInForEmailMFASetupSelectionStep() async {

        do {
            createMFASubscription()
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

            // Step 2: select email to continue setting up
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: MFAType.email.challengeResponse)
            guard case .continueSignInWithEmailMFASetup = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }

            // Step 3: pass an email to setup
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
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

            // step 4: confirm sign in
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

        } catch {
            XCTFail("Received failure with error \(error)")
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
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")

        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
}
