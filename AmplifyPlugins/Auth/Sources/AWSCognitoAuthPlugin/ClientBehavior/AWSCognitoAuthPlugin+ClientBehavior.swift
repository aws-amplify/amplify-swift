//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
#if canImport(Combine)
import Combine
#endif

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

#if canImport(AuthenticationServices)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInRequest.Options?) async throws -> AuthSignInResult {
        let options = options ?? AuthWebUISignInRequest.Options()
        let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                             options: options)
        let task = AWSAuthWebUISignInTask(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            eventName: HubPayload.EventName.Auth.webUISignInAPI
        )
        return try await task.value
    }
    
    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInRequest.Options?) async throws -> AuthSignInResult
    {
        let options = options ?? AuthWebUISignInRequest.Options()
        let request = AuthWebUISignInRequest(presentationAnchor: presentationAnchor,
                                             authProvider: authProvider,
                                             options: options)
        let task = AWSAuthWebUISignInTask(
            request,
            authConfiguration: authConfiguration,
            authStateMachine: authStateMachine,
            eventName: HubPayload.EventName.Auth.socialWebUISignInAPI
        )
        return try await task.value
    }
#endif
    
    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInRequest.Options? = nil) async throws -> AuthSignInResult {
        
        let options = options ?? AuthConfirmSignInRequest.Options()
        let request = AuthConfirmSignInRequest(challengeResponse: challengeResponse,
                                               options: options)
        let task = AWSAuthConfirmSignInTask(request, stateMachine: authStateMachine)
        return try await task.value
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
    
    public func signIn(username: String?,
                       password: String?,
                       options: AuthSignInRequest.Options?) async throws -> AuthSignInResult {
        let options = options ?? AuthSignInRequest.Options()
        let request = AuthSignInRequest(username: username,
                                        password: password,
                                        options: options)
        let task = AWSAuthSignInTask(request, authStateMachine: self.authStateMachine)
        return try await task.value
    }

    public func deleteUser() async throws {
        let task = AWSAuthDeleteUserTask(authStateMachine: self.authStateMachine)
        return try await task.value
    }
}
