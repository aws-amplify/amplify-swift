//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import XCTest

class SignInWithOTPTests: AWSAuthBaseTest {
    
    override func setUp() async throws {
        // Use a custom configuration these tests
        amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginPasswordlessIntegrationTests-amplifyconfiguration"
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }
    
    /// Test successful sign up and sign in of new user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithOTP with a new phone number and OTP destination as `.sms`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignUpAndSignInWithOTPSMS() async throws {
        do {
            let phoneNumber = randomPhoneNumber
            let signInResult = try await Amplify.Auth.signInWithOTP(username: phoneNumber,
                                                                    flow: .signUpAndSignIn,
                                                                    destination: .sms)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .sms(let number) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            XCTAssertEqual(number, phoneNumber)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignUpAndSignIn with a new user should not fail \(error)")
        }
    }
        
    /// Test successful sign up and sign in of a new user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing email and OTP destination as `.email`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignUpAndSignInWithOTPEmail() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: defaultTestEmail,
                                                                    flow: .signUpAndSignIn,
                                                                    destination: .email)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignUpAndSignIn with a new user should not fail \(error)")
        }
    }
    
    /// Test successful sign up and sign in of existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithOTP with a new phone number and OTP destination as `.sms`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    ///    - I sign out the user
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing phone number and OTP destination as `.sms`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///    - I should be able to signOut successfully
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignInWithOTPSMS() async throws {
        let phoneNumber = randomPhoneNumber
        
        // sign up and sign in a user
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: phoneNumber,
                                                                    flow: .signUpAndSignIn,
                                                                    destination: .sms)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .sms(let number) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            XCTAssertEqual(number, phoneNumber)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignUpAndSignIn with a new user should not fail \(error)")
        }
        
        // sign out
        try await signOut(globalSignOut: true)
        
        // sign in the user
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: phoneNumber,
                                                                    flow: .signIn,
                                                                    destination: .sms)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .sms(let number) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            XCTAssertEqual(number, phoneNumber)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignIn with a existing user should not fail \(error)")
        }
    }
    
    /// Test successful sign up and sign in of an existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing email and OTP destination as `.email`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    ///    - I sign out the user
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing email and OTP destination as `.email`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///    - I should be able to signOut successfully
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignInWithOTPEmail() async throws {
        // sign up and sign in a user
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: defaultTestEmail,
                                                                    flow: .signUpAndSignIn,
                                                                    destination: .email)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignUpAndSignIn with a new user should not fail \(error)")
        }
        
        // sign out
        try await signOut(globalSignOut: true)
        
        // sign in the user
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: defaultTestEmail,
                                                                    flow: .signIn,
                                                                    destination: .email)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO: Fetch Challenge Response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignIn with a existing user should not fail \(error)")
        }
    }
    
    private func signOut(globalSignOut: Bool) async throws {
        let options = AuthSignOutRequest.Options(globalSignOut: globalSignOut)
        _ = await Amplify.Auth.signOut(options: options)
    }
}
