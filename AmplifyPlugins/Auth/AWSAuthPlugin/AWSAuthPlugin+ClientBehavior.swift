//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSAuthPlugin {

    public func signUp(username: String,
                       password: String?,
                       options: AuthSignUpOperation.Request.Options?,
                       listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation {
        let options = options ?? AuthSignUpRequest.Options()
        let request = AuthSignUpRequest(username: username,
                                        password: password,
                                        options: options)
        let signUpOperation = AWSAuthSignUpOperation(request,
                                                     authenticationProvider: authenticationProvider,
                                                     listener: listener)
        queue.addOperation(signUpOperation)
        return signUpOperation
    }

    public func confirmSignUp(username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options?,
                              listener: AuthConfirmSignUpOperation.EventListener?) -> AuthConfirmSignUpOperation {
        fatalError()
    }

    public func resendSignUpCode(username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options? = nil,
                                 listener: AuthResendSignUpCodeOperation.EventListener?)
        -> AuthResendSignUpCodeOperation {
            fatalError()
    }

    public func signIn(username: String?,
                       password: String?,
                       options: AuthSignInOperation.Request.Options?,
                       listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation {
        let options = options ?? AuthSignInRequest.Options()
        let request = AuthSignInRequest(username: username,
                                        password: password,
                                        options: options)
        let signInOperation = AWSAuthSignInOperation(request,
                                                     authenticationProvider: authenticationProvider,
                                                     listener: listener)
        queue.addOperation(signInOperation)
        return signInOperation
    }

    public func signInWithSocial(provider: AuthSocialProvider,
                                 token: String,
                                 options: AuthSocialSignInOperation.Request.Options?,
                                 listener: AuthSocialSignInOperation.EventListener?) -> AuthSocialSignInOperation {
        fatalError()

    }

    public func signInWithUI(options: AuthUISignInOperation.Request.Options?,
                             listener: AuthUISignInOperation.EventListener?) -> AuthUISignInOperation {
        fatalError()
    }

    public func fetchAuthState(listener: AuthStateOperation.EventListener?) -> AuthStateOperation {
        fatalError()
    }

    // MARK: - Password Management

    public func forgotPassword(username: String,
                               options: AuthForgotPasswordOperation.Request.Options?,
                               listener: AuthForgotPasswordOperation.EventListener?) -> AuthForgotPasswordOperation {
        fatalError()
    }

    public func confirmForgotPassword(username: String,
                                      newPassword: String,
                                      confirmationCode: String,
                                      options: AuthConfirmForgotPasswordOperation.Request.Options?,
                                      listener: AuthConfirmForgotPasswordOperation.EventListener?) ->
        AuthConfirmForgotPasswordOperation {
            fatalError()
    }

    public func changePassword(currentPassword: String,
                               newPassword: String,
                               options: AuthChangePasswordOperation.Request.Options?,
                               listener: AuthChangePasswordOperation.EventListener?) -> AuthChangePasswordOperation {
        fatalError()
    }

}
