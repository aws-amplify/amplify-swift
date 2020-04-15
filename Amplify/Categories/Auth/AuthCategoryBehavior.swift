//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Auth category that clients will use
public protocol AuthCategoryBehavior {

    /// SignUp a user with the authentication provider.
    ///
    /// If the signUp require multiple steps like passing a confirmation code, use the method
    /// `confirmSignUp` after this api completes. You can check if the user is confirmed or not
    /// using the result `AuthSignUpResult.userConfirmed`.
    ///
    /// - Parameters:
    ///   - username: username to signUp
    ///   - password: password as per the password policy of the provider
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    func signUp(username: String,
                password: String,
                options: AuthSignUpOperation.Request.Options?,
                listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation

    /// Confirms the `signUp` operation.
    ///
    /// Invoke this operation as a follow up for the signUp process if the authentication provider
    /// that you are using required to follow a next step after signUp. Calling this operation without
    /// first calling `signUp` or `resendSignUpCode` may cause an error.
    /// - Parameters:
    ///   - username: Username used that was used to signUp.
    ///   - confirmationCode: Confirmation code received to the user.
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
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
