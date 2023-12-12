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
    
    let verifiedUsername = "<fill-this>"
    
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
            guard case .sms(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            
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
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
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
    
    /// Test successful sign in of existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing phone number and OTP destination as `.sms`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with received code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignInWithOTPSMS() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: verifiedUsername,
                                                                    flow: .signIn,
                                                                    destination: .sms)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .sms(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            
            
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
    
    /// Test successful sign in of an existing user
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
    func testSuccessfulSignInWithOTPEmail() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: verifiedUsername,
                                                                    flow: .signIn,
                                                                    destination: .email)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
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
    
    /// Test error on unsuccessful sign in of existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing phone number and OTP destination as `.sms`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with a wrong code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get an error
    ///
    func testUnsuccessfulSignInWithOTPSMS() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: verifiedUsername,
                                                                    flow: .signIn,
                                                                    destination: .sms)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .sms(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .sms")
                return
            }
            
            let challengeResponse = "bogus-code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTFail("Should fail with an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    /// Test error on unsuccessful sign in of an existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithOTP with a existing email and OTP destination as `.email`
    ///    - I invoke Amplify.Auth.confirmSignInWithOTP with a wrong code
    /// - Then:
    ///    - I should get a `.confirmSignInWithOTP()` as the next step
    ///    - I should get an error
    ///
    func testUnsuccessfulSignInWithOTPEmail() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithOTP(username: verifiedUsername,
                                                                    flow: .signIn,
                                                                    destination: .email)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithOTP(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithOTP()")
                return
            }
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
            let challengeResponse = "bogus-code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithOTP(challengeResponse: challengeResponse)
            XCTFail("Should fail with an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
