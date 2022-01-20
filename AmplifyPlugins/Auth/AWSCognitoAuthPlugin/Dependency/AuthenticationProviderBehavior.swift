//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AuthenticationProviderBehavior {

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void)

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void)

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AuthError>) -> Void)

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void)

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void)

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void)

    func signOut(request: AuthSignOutRequest,
                 completionHandler: @escaping (Result<Void, AuthError>) -> Void)

    func deleteUser(request: AuthDeleteUserRequest,
                    completionHandler: @escaping (Result<Void, AuthError>) -> Void)

    func getCurrentUser() -> AuthUser?

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AuthError>) -> Void)

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AuthError>) -> Void)
}
