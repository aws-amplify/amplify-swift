//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthenticationProviderBehavior: AuthenticationProviderBehavior {

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func signOut(request: AuthSignOutRequest,
                 completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func getCurrentUser() -> AuthUser? {
        fatalError()

    }

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        // Incomplete implementation
    }
}
