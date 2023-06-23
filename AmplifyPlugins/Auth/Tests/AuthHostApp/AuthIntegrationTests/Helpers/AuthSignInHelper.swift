//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

enum AuthSignInHelper {
    
    static func signOut() async {
        let session = try? await Amplify.Auth.fetchAuthSession()
        if session?.isSignedIn ?? false {
            _ = await Amplify.Auth.signOut()
        }
    }

    static func signUpUser(
        username: String,
        password: String,
        email: String,
        phoneNumber: String? = nil) async throws -> Bool {

            var userAttributes = [
                AuthUserAttribute(.email, value: email)
            ]
            if let phoneNumber = phoneNumber {
                userAttributes.append(AuthUserAttribute(.phoneNumber, value: phoneNumber))
            }

            let options = AuthSignUpRequest.Options(
                userAttributes: userAttributes)
            let result = try await Amplify.Auth.signUp(username: username, password: password, options: options)
            return result.isSignUpComplete
        }

    static func signInUser(username: String, password: String) async throws -> AuthSignInResult {
        return try await Amplify.Auth.signIn(username: username, password: password, options: nil)
    }

    static func registerAndSignInUser(
        username: String,
        password: String,
        email: String,
        phoneNumber: String? = nil) async throws -> Bool {
            let signedUp = try await AuthSignInHelper.signUpUser(
                username: username,
                password: password,
                email: email,
                phoneNumber: phoneNumber)
            guard signedUp else {
                throw AuthError.invalidState("Auth sign up failed", "", nil)
            }
            let result = try await AuthSignInHelper.signInUser(username: username, password: password)
            return result.isSignedIn
        }
}
