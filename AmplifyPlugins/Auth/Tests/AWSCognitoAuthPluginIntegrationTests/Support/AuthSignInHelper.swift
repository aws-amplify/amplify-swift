//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

typealias CompletionType = (Bool, AuthError?) -> Void

enum AuthSignInHelper {

    static func signUpUser(username: String,
                           password: String,
                           email: String,
                           completionHandler: @escaping CompletionType)
    {

        let options = AuthSignUpRequest.Options(userAttributes: [AuthUserAttribute(.email, value: email)])
        _ = Amplify.Auth.signUp(username: username, password: password, options: options) { result in
            switch result {
            case .success(let signUpResult):
                completionHandler(signUpResult.isSignUpComplete, nil)
            case .failure(let error):
                completionHandler(false, error)
            }
        }
    }

    static func signInUser(username: String, password: String, completionHandler: @escaping CompletionType) {
        _ = Amplify.Auth.signIn(username: username,
                                password: password) { result in
            switch result {
            case .success(let signInResult):
                completionHandler(signInResult.isSignedIn, nil)
            case .failure(let error):
                completionHandler(false, error)
            }

        }
    }

    static func registerAndSignInUser(username: String,
                                      password: String,
                                      email: String,
                                      completionHandler: @escaping CompletionType)
    {

        AuthSignInHelper.signUpUser(username: username, password: password, email: email) { signUpSuccess, error in
            guard signUpSuccess else {
                completionHandler(signUpSuccess, error)
                return
            }
            AuthSignInHelper.signInUser(username: username, password: password, completionHandler: completionHandler)
        }
    }
}
