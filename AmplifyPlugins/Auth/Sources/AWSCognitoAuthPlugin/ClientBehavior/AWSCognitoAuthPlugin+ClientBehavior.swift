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
                       options: AuthSignUpRequest.Options?) async throws -> AuthSignUpResult {
        let options = options ?? AuthSignUpRequest.Options()
        let request = AuthSignUpRequest(username: username,
                                        password: password,
                                        options: options)
        let task = AWSAuthSignUpTask(request, authEnvironment: authEnvironment)
        return try await task.value
    }
    
    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpRequest.Options?)
    async throws-> AuthSignUpResult {
        let options = options ?? AuthConfirmSignUpRequest.Options()
        let request = AuthConfirmSignUpRequest(username: username,
                                               code: confirmationCode,
                                               options: options)
        let task = AWSAuthConfirmSignUpTask(request, authEnvironment: authEnvironment)
        return try await task.value
    }
    
    public func resendSignUpCode(for username: String, options: AuthResendSignUpCodeRequest.Options?) async throws -> AuthCodeDeliveryDetails {
        let options = options ?? AuthResendSignUpCodeRequest.Options()
        let request = AuthResendSignUpCodeRequest(username: username, options: options)
        let task = AWSAuthResendSignUpCodeTask(request, environment: authEnvironment, authConfiguration: authConfiguration)
        return try await task.value
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
    
    public func signOut(options: AuthSignOutRequest.Options?) async throws {
        let options = options ?? AuthSignOutRequest.Options()
        let request = AuthSignOutRequest(options: options)
        let task = AWSAuthSignOutTask(request, authStateMachine: authStateMachine)
        return try await task.value
    }
    
    public func fetchAuthSession(options: AuthFetchSessionRequest.Options?) async throws -> AuthSession {
        let options = options ?? AuthFetchSessionRequest.Options()
        let request = AuthFetchSessionRequest(options: options)
        let task = AWSAuthFetchSessionTask(request, authStateMachine: authStateMachine)
        return try await task.value
    }
    
    public func resetPassword(for username: String, options: AuthResetPasswordRequest.Options?) async throws -> AuthResetPasswordResult {
        let options = options ?? AuthResetPasswordRequest.Options()
        let request = AuthResetPasswordRequest(username: username, options: options)
        let task = AWSAuthResetPasswordTask(request, environment: authEnvironment, authConfiguration: authConfiguration)
        return try await task.value
    }
    
    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordRequest.Options?) async throws {
        let options = options ?? AuthConfirmResetPasswordRequest.Options()
        let request = AuthConfirmResetPasswordRequest(username: username,
                                                      newPassword: newPassword,
                                                      confirmationCode: confirmationCode,
                                                      options: options)
        let task = AWSAuthConfirmResetPasswordTask(request, environment: authEnvironment, authConfiguration: authConfiguration)
        return try await task.value
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
