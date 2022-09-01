//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public typealias CompletionType = (Bool, AuthError?) -> Void

public struct AuthSignInHelper {

    public static func signUpUser(username: String, password: String, email: String) async throws -> AuthSignUpResult {
        let options = AuthSignUpRequest.Options(userAttributes: [AuthUserAttribute(.email, value: email)])
        return try await Amplify.Auth.signUp(username: username, password: password, options: options)
    }

    public static func signInUser(username: String, password: String) async throws -> AuthSignInResult  {
        return try await Amplify.Auth.signIn(username: username, password: password, options: nil)
    }

    public static func registerAndSignInUser(username: String, password: String, email: String) async throws -> Bool {
        _ = try await AuthSignInHelper.signUpUser(username: username, password: password, email: email)
        let result = try await AuthSignInHelper.signInUser(username: username, password: password)
        return result.isSignedIn
    }
}
