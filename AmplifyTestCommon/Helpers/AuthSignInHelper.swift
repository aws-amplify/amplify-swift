//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public typealias CompletionType = (Bool, AuthError?) -> Void

public struct AuthSignInHelper {

    public static func signUpUser(username: String,
                                  password: String,
                                  email: String,
                                  completionHandler: @escaping CompletionType) {

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

    public static func signInUser(username: String, password: String) async throws -> AuthSignInResult  {
        return try await Amplify.Auth.signIn(username: username, password: password, options: nil)
    }

    public static func registerAndSignInUser(
        username: String,
        password: String,
        email: String,
        completionHandler: @escaping CompletionType) {

            AuthSignInHelper.signUpUser(username: username, password: password, email: email) { signUpSuccess, error in
                guard signUpSuccess else {
                    completionHandler(signUpSuccess, error)
                    return
                }
                
                //Temporary code until signup operation is also migrated to async/await
                Task {
                    do {
                        let result = try await AuthSignInHelper.signInUser(username: username, password: password)
                        completionHandler(result.isSignedIn, nil)
                    } catch {
                        completionHandler(false, error as? AuthError)
                    }
                }
            }
        }
}
