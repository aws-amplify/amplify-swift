//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCategoryClientBehavior {

    func signUp(username: String,
                password: String,
                options: AuthSignUpOperation.Request.Options?,
                listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       options: AuthConfirmSignUpOperation.Request.Options?,
                       listener: AuthConfirmSignUpOperation.EventListener?) -> AuthConfirmSignUpOperation

    func signIn(username: String,
                password: String,
                options: AuthSignInOperation.Request.Options?,
                listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation

    func signInWithSocial(provider: AuthSocialProvider,
                          token: String,
                          options: AuthSocialSignInOperation.Request.Options?,
                          listener: AuthSocialSignInOperation.EventListener?) -> AuthSocialSignInOperation

    func signInWithUI(options: AuthUISignInOperation.Request.Options?,
                      listener: AuthUISignInOperation.EventListener?) -> AuthUISignInOperation

    func fetchAuthState(listener: AuthStateOperation.EventListener?) -> AuthStateOperation

    // MARK: - Password Management

    func forgotPassword(username: String,
                        options: AuthForgotPasswordOperation.Request.Options?,
                        listener: AuthForgotPasswordOperation.EventListener?) -> AuthForgotPasswordOperation

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               options: AuthConfirmForgotPasswordOperation.Request.Options?,
                               listener: AuthConfirmForgotPasswordOperation.EventListener?) ->
    AuthConfirmForgotPasswordOperation

    func changePassword(currentPassword: String,
                        newPassword: String,
                        options: AuthChangePasswordOperation.Request.Options?,
                        listener: AuthChangePasswordOperation.EventListener?) -> AuthChangePasswordOperation
}
