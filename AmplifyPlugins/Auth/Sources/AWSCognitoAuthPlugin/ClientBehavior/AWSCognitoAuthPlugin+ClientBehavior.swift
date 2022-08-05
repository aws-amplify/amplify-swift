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
        let signUpOperation = AWSAuthSignUpOperation(
            request,
            stateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(signUpOperation)
        return signUpOperation
    }
    
    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options?,
                              listener: AuthConfirmSignUpOperation.ResultListener?)
    -> AuthConfirmSignUpOperation {
        let options = options ?? AuthConfirmSignUpRequest.Options()
        let request = AuthConfirmSignUpRequest(username: username,
                                               code: confirmationCode,
                                               options: options)
        let confirmSignUpOperation = AWSAuthConfirmSignUpOperation(
            request,
            stateMachine: authStateMachine, resultListener: listener)
        queue.addOperation(confirmSignUpOperation)
        return confirmSignUpOperation
        
    }
    
    public func resendSignUpCode(for username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options?,
                                 listener: AuthResendSignUpCodeOperation.ResultListener?)
    -> AuthResendSignUpCodeOperation {
        let options = options ?? AuthResendSignUpCodeRequest.Options()
        let request = AuthResendSignUpCodeRequest(username: username, options: options)
        let resendSignUpCodeOperation = AWSAuthResendSignUpCodeOperation(
            request,
            environment: authEnvironment,
            authConfiguration: authConfiguration,
            resultListener: listener)
        queue.addOperation(resendSignUpCodeOperation)
        return resendSignUpCodeOperation
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
            resultListener: listener)
        queue.addOperation(signInOperation)
        return signInOperation
    }
    
#if canImport(AuthenticationServices)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options?,
                                listener: AuthWebUISignInOperation.ResultListener?)
    -> AuthWebUISignInOperation {
        let options = options ?? AuthWebUISignInRequest.Options()
        let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                             options: options)
        let signInWithWebUIOperation = AWSAuthWebUISignInOperation(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(signInWithWebUIOperation)
        return signInWithWebUIOperation
    }
    
    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options?,
                                listener: AuthSocialWebUISignInOperation.ResultListener?)
    -> AuthSocialWebUISignInOperation {
        let options = options ?? AuthWebUISignInRequest.Options()
        let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                             authProvider: authProvider,
                                             options: options)
        let signInWithWebUIOperation = AWSAuthSocialWebUISignInOperation(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(signInWithWebUIOperation)
        return signInWithWebUIOperation
    }
#endif
    
    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.ResultListener?)
    -> AuthConfirmSignInOperation {
        
        let options = options ?? AuthConfirmSignInRequest.Options()
        let request = AuthConfirmSignInRequest(challengeResponse: challengeResponse,
                                               options: options)
        let operation = AWSAuthConfirmSignInOperation(
            request,
            stateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }
    
    public func signOut(options: AuthSignOutOperation.Request.Options?,
                        listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation {
        let options = options ?? AuthSignOutRequest.Options()
        let request = AuthSignOutRequest(options: options)
        let signOutOperation = AWSAuthSignOutOperation(request,
                                                       authStateMachine: authStateMachine,
                                                       resultListener: listener)
        queue.addOperation(signOutOperation)
        return signOutOperation
        
    }
    
    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options?,
                                 listener: AuthFetchSessionOperation.ResultListener?)
    -> AuthFetchSessionOperation {
        let options = options ?? AuthFetchSessionRequest.Options()
        let request = AuthFetchSessionRequest(options: options)
        let fetchAuthSessionOperation = AWSAuthFetchSessionOperation(
            request,
            authStateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(fetchAuthSessionOperation)
        return fetchAuthSessionOperation
    }
    
    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options?,
                              listener: AuthResetPasswordOperation.ResultListener?)
    -> AuthResetPasswordOperation {
        let options = options ?? AuthResetPasswordRequest.Options()
        let request = AuthResetPasswordRequest(username: username, options: options)
        let resetPasswordOperation = AWSAuthResetPasswordOperation(
            request,
            environment: authEnvironment,
            authConfiguration: authConfiguration,
            resultListener: listener)
        queue.addOperation(resetPasswordOperation)
        return resetPasswordOperation
    }
    
    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options?,
                                     listener: AuthConfirmResetPasswordOperation.ResultListener?)
    -> AuthConfirmResetPasswordOperation {
        let options = options ?? AuthConfirmResetPasswordRequest.Options()
        let request = AuthConfirmResetPasswordRequest(username: username,
                                                      newPassword: newPassword,
                                                      confirmationCode: confirmationCode,
                                                      options: options)
        let confirmResetPasswordOperation = AWSAuthConfirmResetPasswordOperation(
            request,
            environment: authEnvironment,
            authConfiguration: authConfiguration,
            resultListener: listener)
        queue.addOperation(confirmResetPasswordOperation)
        return confirmResetPasswordOperation
    }
    
    public func deleteUser(listener: AuthDeleteUserOperation.ResultListener?)
    -> AuthDeleteUserOperation {
        let request = AuthDeleteUserRequest()
        let deleteUserOperation = AWSAuthDeleteUserOperation(
            request,
            authStateMachine: authStateMachine,
            resultListener: listener)
        queue.addOperation(deleteUserOperation)
        return deleteUserOperation
    }
    
}
