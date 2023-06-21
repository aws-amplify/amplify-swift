//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin

class MFASignInTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test successful successful signIn with confirmSignInWithTOTPCode Step
    ///
    /// - Given: A newly signed up user in Cognito user pool
    ///    Following are the preconditions to set up the test
    ///     - Sign Up and Sign In
    ///     - Set Up TOTP
    ///     - Set TOTP as preferred
    ///     - Sign out
    ///
    /// - When:
    ///    - I invoke signIn and confirmSignIn API
    /// - Then:
    ///    - I should get confirmSignInWithTOTPCode Step for signIn call and can be successfully confirmed
    ///
    func testSignInWithTOTPMFA() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")

        let authCognitoPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

        let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
        let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
        try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
        try await authCognitoPlugin.updateMFAPreference(
            sms: nil,
            totp: .enabled)
        await AuthSignInHelper.signOut()

        /// Sleep for 30 secs so that TOTP code can be regenerated for use during sign in otherwise will get
        /// RespondToAuthChallengeOutputError.expiredCodeException
        ///  - "Your software token has already been used once."
        ///
        Amplify.Logging.info("Sleeping for 30 seconds to avoid RespondToAuthChallengeOutputError.expiredCodeException")
        try await Task.sleep(seconds: 30)

        // WHEN

        // Once all preconditions are satisfied, try signing in
        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .confirmSignInWithTOTPCode = result.nextStep else {
                XCTFail("Next step should be confirmSignInWithTOTPCode")
                return
            }
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: totpCode)
            XCTAssertTrue(confirmSignInResult.isSignedIn)

        } catch {
            XCTFail("SignIn should successfully complete. \(error)")
        }

        // Clean up user
        try await Amplify.Auth.deleteUser()
    }

    /// Test successful successful signIn with confirmSignInWithSMSMFACode Step
    ///
    /// - Given: A newly signed up user in Cognito user pool
    ///    Following are the preconditions to set up the test
    ///     - Sign Up and Sign In
    ///     - Set SMS as preferred
    ///     - Sign out
    ///
    /// - When:
    ///    - I invoke signIn and confirmSignIn API
    /// - Then:
    ///    - I should get confirmSignInWithSMSMFACode Step for signIn call and can be successfully confirmed
    ///
    func testSignInWithSMSMFA() async throws {

        // GIVEN

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail,
            phoneNumber: "+16135550116")

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")

        let authCognitoPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin
        try await authCognitoPlugin.updateMFAPreference(
            sms: .enabled,
            totp: nil)
        await AuthSignInHelper.signOut()


        // WHEN

        // Once all preconditions are satisfied, try signing in
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
            XCTFail("SignIn should successfully complete. \(error)")
        }

    }

    /// Test successful successful signIn with continueSignInWithMFASelection Step
    ///
    /// - Given: A newly signed up user in Cognito user pool
    ///    Following are the preconditions to set up the test
    ///     - Sign Up and Sign In
    ///     - Set Up TOTP
    ///     - Set TOTP as preferred
    ///     - Sign out
    ///
    /// - When:
    ///    - I invoke signIn and confirmSignIn API
    /// - Then:
    ///    - I should get continueSignInWithMFASelection Step for signIn call and can be successfully confirmed
    ///
    func testSelectMFATypeWithTOTPWhileSigningIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail,
            phoneNumber: "+16135550116")

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")

        let authCognitoPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

        let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
        let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
        try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
        try await authCognitoPlugin.updateMFAPreference(
            sms: .enabled,
            totp: .enabled)
        await AuthSignInHelper.signOut()

        /// Sleep for 30 secs so that TOTP code can be regenerated for use during sign in otherwise will get
        /// RespondToAuthChallengeOutputError.expiredCodeException
        ///  - "Your software token has already been used once."
        ///
        Amplify.Logging.info("Sleeping for 30 seconds to avoid RespondToAuthChallengeOutputError.expiredCodeException")
        try await Task.sleep(seconds: 30)

        // Once all preconditions are satisfied, try signing in

        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .continueSignInWithMFASelection(let allowedMFATypes) = result.nextStep else {
                XCTFail("Next step should be continueSignInWithMFASelection")
                return
            }
            XCTAssertEqual(allowedMFATypes, [.sms, .totp])

            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: MFAType.totp.challengeResponse)

            guard case .confirmSignInWithTOTPCode = confirmSignInResult.nextStep else {
                XCTFail("Next step should be confirmSignInWithTOTPCode")
                return
            }

            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: totpCode)
            XCTAssertTrue(confirmSignInResult.isSignedIn)

        } catch {
            XCTFail("SignIn should successfully complete. \(error)")
        }

        // Clean up user
        try await Amplify.Auth.deleteUser()
    }

    /// Test successful successful signIn with continueSignInWithMFASelection Step
    ///
    /// - Given: A newly signed up user in Cognito user pool
    ///    Following are the preconditions to set up the test
    ///     - Sign Up and Sign In
    ///     - Set Up TOTP
    ///     - Set TOTP as preferred
    ///     - Sign out
    ///
    /// - When:
    ///    - I invoke signIn and confirmSignIn API
    /// - Then:
    ///    - I should get continueSignInWithMFASelection Step for signIn call and can be successfully confirmed
    ///
    func testSelectMFATypeWithSMSWhileSigningIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail,
            phoneNumber: "+16135550116")

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")

        let authCognitoPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

        let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
        let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
        try await Amplify.Auth.verifyTOTPSetup(code: totpCode)
        try await authCognitoPlugin.updateMFAPreference(
            sms: .enabled,
            totp: .enabled)
        await AuthSignInHelper.signOut()

        // Once all preconditions are satisfied, try signing in
        do {
            let result = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init())
            guard case .continueSignInWithMFASelection(let allowedMFATypes) = result.nextStep else {
                XCTFail("Next step should be continueSignInWithMFASelection")
                return
            }
            XCTAssertEqual(allowedMFATypes, [.sms, .totp])

            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: MFAType.sms.challengeResponse)

            guard case .confirmSignInWithSMSMFACode(let codeDeliveryDetails, _) = confirmSignInResult.nextStep else {
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
            XCTFail("SignIn should successfully complete. \(error)")
        }
    }

}
