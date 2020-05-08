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
    
    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.EventListener?) -> AuthConfirmSignInOperation {
        return plugin.confirmSignIn(challengeResponse: challengeResponse,
                                    options: options,
                                    listener: listener)
    }
    
    public func signOut(options: AuthSignOutOperation.Request.Options? = nil,
                        listener: AuthSignOutOperation.EventListener?) -> AuthSignOutOperation {
        plugin.signOut(options: options, listener: listener)
    }
    
    public func fetchAuthState(listener: AuthStateOperation.EventListener?) -> AuthStateOperation {
        return plugin.fetchAuthState(listener: listener)
    }
    
    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options? = nil,
                              listener: AuthResetPasswordOperation.EventListener?) -> AuthResetPasswordOperation {
        return plugin.resetPassword(for: username,
                                    options: options,
                                    listener: listener)
    }
    
    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options? = nil,
                                     listener: AuthConfirmResetPasswordOperation.EventListener?)
        -> AuthConfirmResetPasswordOperation {
            return plugin.confirmResetPassword(for: username,
                                               with: newPassword,
                                               confirmationCode: confirmationCode,
                                               options: options,
                                               listener: listener)
    }
}
