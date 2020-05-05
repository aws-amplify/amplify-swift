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

    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options?,
                                listener: AuthWebUISignInOperation.EventListener?) -> AuthWebUISignInOperation {
        let options = options ?? AuthWebUISignInRequest.Options()
        let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                             options: options)
        let signInWithWebUIOperation = AWSAuthWebUISignInOperation(request,
                                                                   authenticationProvider: authenticationProvider,
                                                                   listener: listener)
        queue.addOperation(signInWithWebUIOperation)
        return signInWithWebUIOperation
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options?,
                                listener: AuthSocialWebUISignInOperation.EventListener?)
        -> AuthSocialWebUISignInOperation {
            let options = options ?? AuthWebUISignInRequest.Options()
            let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                                 authProvider: authProvider,
                                                 options: options)
            let signInWithWebUIOperation = AWSAuthSocialWebUISignInOperation(
                request,
                authenticationProvider: authenticationProvider,
                listener: listener)
            queue.addOperation(signInWithWebUIOperation)
            return signInWithWebUIOperation
    }

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.EventListener?) -> AuthConfirmSignInOperation {
        let options = options ?? AuthConfirmSignInRequest.Options()
        let request = AuthConfirmSignInRequest(challengeResponse: challengeResponse, options: options)
        let confirmSignInOperation = AWSAuthConfirmSignInOperation(request,
                                                                   authenticationProvider: authenticationProvider,
                                                                   listener: listener)
        queue.addOperation(confirmSignInOperation)
        return confirmSignInOperation
    }

    public func signOut(options: AuthSignOutRequest.Options?, listener: AuthSignOutOperation.EventListener?)
        -> AuthSignOutOperation {
            let options = options ?? AuthSignOutRequest.Options()
            let request = AuthSignOutRequest(options: options)
            let signOutOperation = AWSAuthSignOutOperation(request,
                                                           authenticationProvider: authenticationProvider,
                                                           listener: listener)
            queue.addOperation(signOutOperation)
            return signOutOperation
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
