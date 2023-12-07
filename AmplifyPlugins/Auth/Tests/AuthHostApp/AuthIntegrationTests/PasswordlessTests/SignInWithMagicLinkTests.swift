//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import XCTest

class SignInWithMagicLinkTests: AWSAuthBaseTest {
    
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
    ///    - I invoke Amplify.Auth.signInWithMagicLink with a new email
    ///    - I invoke Amplify.Auth.confirmSignInWithMagicLink
    /// - Then:
    ///    - I should get a `.confirmSignInWithMagicLink()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignUpAndSignInWithMagicLink() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithMagicLink(username: defaultTestEmail,
                                                                          flow: .signUpAndSignIn,
                                                                          redirectURL: defaultRedirectURL)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithMagicLink(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithMagicLink()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO : Fetch the challenge response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithMagicLink(challengeResponse: challengeResponse)
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
    ///    - I invoke Amplify.Auth.signInWithMagicLink with a new email
    ///    - I invoke Amplify.Auth.confirmSignInWithMagicLink
    /// - Then:
    ///    - I should get a `.confirmSignInWithMagicLink()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignInWithMagicLink() async throws {
        // Sign up and sign in a new user
        do {
            let signInResult = try await Amplify.Auth.signInWithMagicLink(username: defaultTestEmail,
                                                                          flow: .signUpAndSignIn,
                                                                          redirectURL: defaultRedirectURL)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithMagicLink(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithMagicLink()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO : Fetch the challenge response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithMagicLink(challengeResponse: challengeResponse)
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
            let signInResult = try await Amplify.Auth.signInWithMagicLink(username: defaultTestEmail,
                                                                          flow: .signIn,
                                                                          redirectURL: defaultRedirectURL)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithMagicLink(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithMagicLink()")
                return
            }
            guard case .email(let email) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            XCTAssertEqual(email, defaultTestEmail)
            
            // TODO : Fetch the challenge response
            let challengeResponse = "code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithMagicLink(challengeResponse: challengeResponse)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Next step should be .done")
                return
            }
        } catch {
            XCTFail("SignIn with an existing user should not fail \(error)")
        }
    }
    
    private func signOut(globalSignOut: Bool) async throws {
        let options = AuthSignOutRequest.Options(globalSignOut: globalSignOut)
        _ = await Amplify.Auth.signOut(options: options)
    }
}
