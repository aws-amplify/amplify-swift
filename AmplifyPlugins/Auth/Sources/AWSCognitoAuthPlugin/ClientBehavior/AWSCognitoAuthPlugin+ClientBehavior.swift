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
                       listener: AuthSignUpOperation.ResultListener?) -> AuthSignUpOperation {
        let options = options ?? AuthSignUpRequest.Options()
        let request = AuthSignUpRequest(username: username,
                                        password: password,
                                        options: options)
        let signUpOperation = AWSAuthSignUpOperation(request, stateMachine: authStateMachine, resultListener: listener)
        queue.addOperation(signUpOperation)
        return signUpOperation
    }

    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options?,
                              listener: AuthConfirmSignUpOperation.ResultListener?) -> AuthConfirmSignUpOperation {
        let options = options ?? AuthConfirmSignUpRequest.Options()
        let request = AuthConfirmSignUpRequest(username: username, code: confirmationCode, options: options)
        let confirmSignUpOperation = AWSAuthConfirmSignUpOperation(request, stateMachine: authStateMachine, resultListener: listener)
        queue.addOperation(confirmSignUpOperation)
        return confirmSignUpOperation

    }

    public func resendSignUpCode(for username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options?,
                                 listener: AuthResendSignUpCodeOperation.ResultListener?) -> AuthResendSignUpCodeOperation {
        fatalError("Not implemented")
    }

    public func signIn(username: String?,
                       password: String?,
                       options: AuthSignInOperation.Request.Options?,
                       listener: AuthSignInOperation.ResultListener?) -> AuthSignInOperation {
        let options = options ?? AuthSignInRequest.Options()
        let request = AuthSignInRequest(username: username,
                                        password: password,
                                        options: options)
        let signInOperation = AWSAuthSignInOperation(
            request,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine,
            resultListener: listener)
        queue.addOperation(signInOperation)
        return signInOperation
    }

#if canImport(AuthenticationServices)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options?,
                                listener: AuthWebUISignInOperation.ResultListener?) -> AuthWebUISignInOperation {
        fatalError("Not implemented")
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options?,
                                listener: AuthSocialWebUISignInOperation.ResultListener?) -> AuthSocialWebUISignInOperation {
        fatalError("Not implemented")
    }
#endif

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options?,
                              listener: AuthConfirmSignInOperation.ResultListener?) -> AuthConfirmSignInOperation
    {
        fatalError("Not implemented")
    }

    public func signOut(options: AuthSignOutOperation.Request.Options?,
                        listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation {
        let options = options ?? AuthSignOutRequest.Options()
        let request = AuthSignOutRequest(options: options)
        let signOutOperation = AWSAuthSignOutOperation(request,
                                                       authStateMachine: authStateMachine,
                                                       credentialStoreStateMachine: credentialStoreStateMachine,
                                                       resultListener: listener)
        queue.addOperation(signOutOperation)
        return signOutOperation

    }

    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options?,
                                 listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation {
        let options = options ?? AuthFetchSessionRequest.Options()
        let request = AuthFetchSessionRequest(options: options)
        let fetchAuthSessionOperation = AWSAuthFetchSessionOperation(request,
                                                                     authStateMachine: authStateMachine,
                                                                     credentialStoreStateMachine: credentialStoreStateMachine,
                                                                     resultListener: listener)
        queue.addOperation(fetchAuthSessionOperation)
        return fetchAuthSessionOperation
    }

    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options?,
                              listener: AuthResetPasswordOperation.ResultListener?) -> AuthResetPasswordOperation {
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

    public func deleteUser(listener: AuthDeleteUserOperation.ResultListener?) -> AuthDeleteUserOperation {
        fatalError("Not implemented")
    }

}
