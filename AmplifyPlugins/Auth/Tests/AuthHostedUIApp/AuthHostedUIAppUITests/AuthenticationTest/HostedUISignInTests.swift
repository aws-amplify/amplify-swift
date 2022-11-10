//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class HostedUISignInTests: UITestCase {

    func testSignInSuccess() throws {

        let username = "hostedUI-\(UUID().uuidString)@amazon.com"
        let password = "P123@\(UUID().uuidString)"
        let signInScreen = SignInScreen(app: app)
        let signUpScreen = signInScreen.gotoSignUpView()
        _ = signUpScreen
            .enterFields(username: username, password: password)
            .tapSignUp()
            .testSignUpSucceeded()
            .returnBack()

        _ = signInScreen
            .tapSignIn()
            .dismissSignInAlert()
            .signIn(username: username, password: password)
            .testSignInSucceeded()
            
    }

    func testSignInWithoutPresentationAnchorSuccess() throws {
        let username = "hostedUI-\(UUID().uuidString)@amazon.com"
        let password = "P123@\(UUID().uuidString)"
        let signInScreen = SignInScreen(app: app)
        let signUpScreen = signInScreen.gotoSignUpView()
        _ = signUpScreen
            .enterFields(username: username, password: password)
            .tapSignUp()
            .testSignUpSucceeded()
            .returnBack()

        _ = signInScreen
            .tapSignInWithoutPresentationAnchor()
            .dismissSignInAlert()
            .signIn(username: username, password: password)
            .testSignInSucceeded()

    }

}
