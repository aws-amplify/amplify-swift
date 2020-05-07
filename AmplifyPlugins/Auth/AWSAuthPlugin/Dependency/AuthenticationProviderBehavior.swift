//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AuthenticationProviderBehavior {

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void)

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void)

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AmplifyAuthError>) -> Void)

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping (Result<AuthSignInResult, AmplifyAuthError>) -> Void)

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping (Result<AuthSignInResult, AmplifyAuthError>) -> Void)

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping (Result<AuthSignInResult, AmplifyAuthError>) -> Void)

    func signOut(request: AuthSignOutRequest,
                 completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void)

    func signInUsername() -> Result<String, AmplifyAuthError>

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AmplifyAuthError>) -> Void)

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void)
}
