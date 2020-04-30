//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryBehavior {

    public func signUp(username: String,
                       password: String? = nil,
                       options: AuthSignUpOperation.Request.Options? = nil,
                       listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation {
        return plugin.signUp(username: username,
                             password: password,
                             options: options,
                             listener: listener)
    }

    public func confirmSignUp(username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options? = nil,
                              listener: AuthConfirmSignUpOperation.EventListener?) -> AuthConfirmSignUpOperation {
        return plugin.confirmSignUp(username: username,
                                    confirmationCode: confirmationCode,
                                    options: options,
                                    listener: listener)
    }

    public func resendSignUpCode(username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options? = nil,
                                 listener: AuthResendSignUpCodeOperation.EventListener?)
        -> AuthResendSignUpCodeOperation {
            return plugin.resendSignUpCode(username: username,
                                           options: options,
                                           listener: listener)
    }

    public func signIn(username: String? = nil,
                       password: String? = nil,
                       options: AuthSignInOperation.Request.Options? = nil,
                       listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation {
        return plugin.signIn(username: username,
                             password: password,
                             options: options,
                             listener: listener)
    }

    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options? = nil,
                                listener: AuthWebUISignInOperation.EventListener?) -> AuthWebUISignInOperation {
        return plugin.signInWithWebUI(presentationAnchor: presentationAnchor,
                                      options: options,
                                      listener: listener)
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options? = nil,
                                listener: AuthSocialWebUISignInOperation.EventListener?)
        -> AuthSocialWebUISignInOperation {
            return plugin.signInWithWebUI(for: authProvider,
                                          presentationAnchor: presentationAnchor,
                                          options: options,
                                          listener: listener)
    }

    public func fetchAuthState(listener: AuthStateOperation.EventListener?) -> AuthStateOperation {
        return plugin.fetchAuthState(listener: listener)
    }

    public func forgotPassword(username: String,
                               options: AuthForgotPasswordOperation.Request.Options? = nil,
                               listener: AuthForgotPasswordOperation.EventListener?) -> AuthForgotPasswordOperation {
        return plugin.forgotPassword(username: username,
                                     options: options,
                                     listener: listener)
    }

    public func confirmForgotPassword(username: String,
                                      newPassword: String,
                                      confirmationCode: String,
                                      options: AuthConfirmForgotPasswordOperation.Request.Options? = nil,
                                      listener: AuthConfirmForgotPasswordOperation.EventListener?) -> AuthConfirmForgotPasswordOperation {
        return plugin.confirmForgotPassword(username: username,
                                            newPassword: newPassword,
                                            confirmationCode: confirmationCode,
                                            options: options,
                                            listener: listener)
    }

    public func changePassword(currentPassword: String,
                               newPassword: String,
                               options: AuthChangePasswordOperation.Request.Options? = nil,
                               listener: AuthChangePasswordOperation.EventListener?) -> AuthChangePasswordOperation {
        return plugin.changePassword(currentPassword: currentPassword,
                                     newPassword: newPassword,
                                     options: options,
                                     listener: listener)
    }
}
