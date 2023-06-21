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
    func testSetupMFANextStepDuringSignIn() async throws {

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
            XCTFail("Should get valid next step. \(error)")
        }
    }

    /// Test successful next step confirmSignInWithSMSMFACode
    ///
    /// - Given: A newly signed up user in Cognito user pool with REQUIRED MFA, Phone Number ADDED
    ///
    /// - When:
    ///    - I invoke signIn API
    /// - Then:
    ///    - I should get confirmSignInWithSMSMFACode Step for signIn call and can be successfully confirmed
    ///
    func testSMSMFANextStepDuringSignIn() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail,
            phoneNumber: "+16135550116")

        XCTAssertTrue(didSucceed, "Signup should succeed")

        // WHEN

        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .confirmSignInWithSMSMFACode(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Next step should be confirmSignInWithSMSMFACode")
                return
            }
            guard case .sms(let destination) = codeDeliveryDetails.destination else {
                XCTFail("Destination should be phone")
                return
            }
            XCTAssertNotNil(destination)

            Amplify.Logging.info("Cannot use confirmSignIn, because don't have access to SMS")

        } catch {
            XCTFail("Should get valid next step. \(error)")
        }
    }


    /// Test successful  successful sign in after continueSignInWithTOTPSetup next step
    ///
    /// - Given: A newly signed up user in Cognito user pool with REQUIRED MFA, No Phone Number Added
    ///
    /// - When:
    ///    - I invoke signIn API
    /// - Then:
    ///    - I should get continueSignInWithTOTPSetup Step for signIn call and can be successfully confirmed
    ///      with TOTP setup confirmation
    ///
    func testSuccessfulSignForSetupMFANextStep() async throws {

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

            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: totpCode)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            
        } catch {
            XCTFail("SignIn should successfully complete. \(error)")
        }
    }

    /// Test successful  successful sign in after continueSignInWithTOTPSetup next step
    ///
    /// - Given: A newly signed up user in Cognito user pool with REQUIRED MFA, No Phone Number Added
    ///
    /// - When:
    ///    - I invoke signIn API and enter invalid alphabetical TOTP setup code to initiate softwareTokenMFANotEnabled
    /// - Then:
    ///    - I should get continueSignInWithTOTPSetup Step for signIn call and can be successfully confirmed
    ///      with TOTP setup confirmation
    ///
    func testSuccessfulSignInForSetupMFANextStepAfterInvalidInitialEntry() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup should succeed")

        // WHEN

        var totpSetupDetails: TOTPSetupDetails?
        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .continueSignInWithTOTPSetup(let details) = result.nextStep else {
                XCTFail("Next step should be continueSignInWithTOTPSetup")
                return
            }
            totpSetupDetails = details
            XCTAssertNotNil(totpSetupDetails?.sharedSecret)

            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: "123456")

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
                let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: totpCode)
                XCTAssertTrue(confirmSignInResult.isSignedIn)
            } catch {
                XCTFail("SignIn should successfully complete. \(error)")
            }

        }
    }

    /// Test successful  successful sign in after continueSignInWithTOTPSetup next step
    ///
    /// - Given: A newly signed up user in Cognito user pool with REQUIRED MFA, No Phone Number Added
    ///
    /// - When:
    ///    - I invoke signIn API and enter invalid alphabetical TOTP setup code to initiate invalidParameterException
    /// - Then:
    ///    - I should get continueSignInWithTOTPSetup Step for signIn call and can be successfully confirmed
    ///      with TOTP setup confirmation
    ///
    func testSuccessfulSignInForSetupMFANextStepAfterInvalidParameterException() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup should succeed")

        // WHEN

        var totpSetupDetails: TOTPSetupDetails?
        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .continueSignInWithTOTPSetup(let details) = result.nextStep else {
                XCTFail("Next step should be continueSignInWithTOTPSetup")
                return
            }
            totpSetupDetails = details
            XCTAssertNotNil(totpSetupDetails?.sharedSecret)

            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: "userCode")

        } catch {

            guard let authError = error as? AuthError,
                  case .service(_, _, let underlyingError) = authError else {
                XCTFail("Should throw service error")
                return
            }

            guard case .invalidParameter = underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should throw invalidParameter error.")
                return
            }

            do {
                let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails!.sharedSecret)
                let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: totpCode)
                XCTAssertTrue(confirmSignInResult.isSignedIn)
            } catch {
                XCTFail("SignIn should successfully complete. \(error)")
            }

        }
    }

}
