//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSCognitoAuthPlugin: AuthCategoryBehavior {

    public func signUp(username: String,
                       password: String?,
                       options: AuthSignUpOperation.Request.Options?,
                       listener: AuthSignUpOperation.ResultListener?) -> AuthSignUpOperation
    {
        fatalError("Not implemented")
    }

    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options?,
                              listener: AuthConfirmSignUpOperation.ResultListener?) -> AuthConfirmSignUpOperation
    {
        fatalError("Not implemented")
    }

    public func resendSignUpCode(for username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options?,
                                 listener: AuthResendSignUpCodeOperation.ResultListener?) -> AuthResendSignUpCodeOperation
    {
        fatalError("Not implemented")
    }

    public func signIn(username: String?,
                       password: String?,
                       options: AuthSignInOperation.Request.Options?,
                       listener: AuthSignInOperation.ResultListener?) -> AuthSignInOperation
    {
        let options = options ?? AuthSignInRequest.Options()
        let request = AuthSignInRequest(username: username,
                                        password: password,
                                        options: options)
        let signInOperation = AWSAuthSignInOperation(request, stateMachine: stateMachine, resultListener: listener)
        queue.addOperation(signInOperation)
        return signInOperation
    }

    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options?,
                                listener: AuthWebUISignInOperation.ResultListener?) -> AuthWebUISignInOperation
    {
        fatalError("Not implemented")
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options?,
                                listener: AuthSocialWebUISignInOperation.ResultListener?) -> AuthSocialWebUISignInOperation
    {
        fatalError("Not implemented")
    }

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options?,
                              listener: AuthConfirmSignInOperation.ResultListener?) -> AuthConfirmSignInOperation
    {
        fatalError("Not implemented")
    }

    public func signOut(options: AuthSignOutOperation.Request.Options?,
                        listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation
    {
        fatalError("Not implemented")
    }

    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options?,
                                 listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation
    {
        fatalError("Not implemented")
    }

    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options?,
                              listener: AuthResetPasswordOperation.ResultListener?) -> AuthResetPasswordOperation
    {
        fatalError("Not implemented")
    }

    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options?,
                                     listener: AuthConfirmResetPasswordOperation.ResultListener?)
    -> AuthConfirmResetPasswordOperation {
        fatalError("Not implemented")
    }


}
