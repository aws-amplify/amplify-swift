//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public extension AWSCognitoAuthPlugin {

    func fetchUserAttributes(options: AuthFetchUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttribute] {
        let options = options ?? AuthFetchUserAttributesRequest.Options()
        let request = AuthFetchUserAttributesRequest(options: options)
        let task = AWSAuthFetchUserAttributeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options? = nil) async throws -> AuthUpdateAttributeResult {

        let options = options ?? AuthUpdateUserAttributeRequest.Options()
        let request = AuthUpdateUserAttributeRequest(userAttribute: userAttribute, options: options)
        let task = AWSAuthUpdateUserAttributeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func update(userAttributes: [AuthUserAttribute],
                options: AuthUpdateUserAttributesRequest.Options? = nil)
    async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {

        let options = options ?? AuthUpdateUserAttributesRequest.Options()
        let request = AuthUpdateUserAttributesRequest(userAttributes: userAttributes, options: options)
        let task = AWSAuthUpdateUserAttributesTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                options: AuthAttributeResendConfirmationCodeRequest.Options? = nil) async throws -> AuthCodeDeliveryDetails {

        let options = options ?? AuthAttributeResendConfirmationCodeRequest.Options()
        let request = AuthAttributeResendConfirmationCodeRequest(attributeKey: attributeKey, options: options)
        let task = AWSAuthAttributeResendConfirmationCodeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func confirm(userAttribute: AuthUserAttributeKey, confirmationCode: String, options: AuthConfirmUserAttributeRequest.Options? = nil) async throws {
        let options = options ?? AuthConfirmUserAttributeRequest.Options()
        let request = AuthConfirmUserAttributeRequest(
            attributeKey: userAttribute,
            confirmationCode: confirmationCode,
            options: options)
        let task = AWSAuthConfirmUserAttributeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        try await task.value
    }

    func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options? = nil) async throws {
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword, options: options)
        let task = AWSAuthChangePasswordTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func getCurrentUser() async -> AuthUser? {
        
        await AWSAuthTaskHelper(authStateMachine: authStateMachine).didStateMachineConfigured()
        let authState = await authStateMachine.currentState
        if case .configured(let authenticationState, _) = authState,
           case .signedIn(let signInData) = authenticationState {
            let authUser = AWSCognitoAuthUser(username: signInData.userName, userId: signInData.userId)
            return authUser
        } else {
            return nil
        }
    }
}
