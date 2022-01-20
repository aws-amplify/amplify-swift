//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryBehavior {

    @discardableResult
    public func signUp(username: String,
                       password: String? = nil,
                       options: AuthSignUpOperation.Request.Options? = nil,
                       listener: AuthSignUpOperation.ResultListener?) -> AuthSignUpOperation {
        return plugin.signUp(username: username,
                             password: password,
                             options: options,
                             listener: listener)
    }

    @discardableResult
    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options? = nil,
                              listener: AuthConfirmSignUpOperation.ResultListener?) -> AuthConfirmSignUpOperation {
        return plugin.confirmSignUp(for: username,
                                    confirmationCode: confirmationCode,
                                    options: options,
                                    listener: listener)
    }

    @discardableResult
    public func resendSignUpCode(for username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options? = nil,
                                 listener: AuthResendSignUpCodeOperation.ResultListener?)
        -> AuthResendSignUpCodeOperation {
            return plugin.resendSignUpCode(for: username,
                                           options: options,
                                           listener: listener)
    }

    @discardableResult
    public func signIn(username: String? = nil,
                       password: String? = nil,
                       options: AuthSignInOperation.Request.Options? = nil,
                       listener: AuthSignInOperation.ResultListener?) -> AuthSignInOperation {
        return plugin.signIn(username: username,
                             password: password,
                             options: options,
                             listener: listener)
    }

    @discardableResult
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options? = nil,
                                listener: AuthWebUISignInOperation.ResultListener?) -> AuthWebUISignInOperation {
        return plugin.signInWithWebUI(presentationAnchor: presentationAnchor,
                                      options: options,
                                      listener: listener)
    }

    @discardableResult
    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options? = nil,
                                listener: AuthSocialWebUISignInOperation.ResultListener?)
        -> AuthSocialWebUISignInOperation {
            return plugin.signInWithWebUI(for: authProvider,
                                          presentationAnchor: presentationAnchor,
                                          options: options,
                                          listener: listener)
    }

    @discardableResult
    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.ResultListener?) -> AuthConfirmSignInOperation {
        return plugin.confirmSignIn(challengeResponse: challengeResponse,
                                    options: options,
                                    listener: listener)
    }

    @discardableResult
    public func signOut(options: AuthSignOutOperation.Request.Options? = nil,
                        listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation {
        plugin.signOut(options: options, listener: listener)
    }

    @discardableResult
    public func deleteUser(listener: AuthDeleteUserOperation.ResultListener?) -> AuthDeleteUserOperation {
        plugin.deleteUser(listener: listener)
    }

    @discardableResult
    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options? = nil,
                                 listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation {
        return plugin.fetchAuthSession(options: options,
                                       listener: listener)
    }

    @discardableResult
    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options? = nil,
                              listener: AuthResetPasswordOperation.ResultListener?) -> AuthResetPasswordOperation {
        return plugin.resetPassword(for: username,
                                    options: options,
                                    listener: listener)
    }

    @discardableResult
    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options? = nil,
                                     listener: AuthConfirmResetPasswordOperation.ResultListener?)
        -> AuthConfirmResetPasswordOperation {
            return plugin.confirmResetPassword(for: username,
                                               with: newPassword,
                                               confirmationCode: confirmationCode,
                                               options: options,
                                               listener: listener)
    }
}
