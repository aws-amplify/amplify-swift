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
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
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
    
    /// Test successful sign in of existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithMagicLink with a existing email
    ///    - I invoke Amplify.Auth.confirmSignInWithMagicLink
    /// - Then:
    ///    - I should get a `.confirmSignInWithMagicLink()` as the next step
    ///    - I should get a `.done` as the next step and `isSigned` as true
    ///
    func testSuccessfulSignInWithMagicLink() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithMagicLink(username: verifiedUsername,
                                                                          flow: .signIn,
                                                                          redirectURL: defaultRedirectURL)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithMagicLink(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithMagicLink()")
                return
            }
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
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
    
    /// Test error when unsuccessful sign in of existing user
    ///
    /// - Given:
    ///     A Cognito Custom Auth backend setup with lambdas for passwordless sign in
    /// - When:
    ///    - I invoke Amplify.Auth.signInWithMagicLink with a existing email
    ///    - I invoke Amplify.Auth.confirmSignInWithMagicLink with a wrong code
    /// - Then:
    ///    - I should get a `.confirmSignInWithMagicLink()` as the next step
    ///    - I should get an error
    ///
    func testUnsuccessfulSignInWithMagicLink() async throws {
        do {
            let signInResult = try await Amplify.Auth.signInWithMagicLink(username: verifiedUsername,
                                                                          flow: .signIn,
                                                                          redirectURL: defaultRedirectURL)
            XCTAssertFalse(signInResult.isSignedIn, "SignIn should not be complete")
            guard case .confirmSignInWithMagicLink(let deliveryDetails, _) = signInResult.nextStep else {
                XCTFail("Sign In Next step should be .confirmSignInWithMagicLink()")
                return
            }
            guard case .email(_) = deliveryDetails.destination else {
                XCTFail("Delivery destination should be .email")
                return
            }
            
            let challengeResponse = "bogus-code"
            let confirmSignInResult = try await Amplify.Auth.confirmSignInWithMagicLink(challengeResponse: challengeResponse)
            XCTFail("Should fail with an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
