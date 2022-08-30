//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public extension AWSCognitoAuthPlugin {

    func fetchUserAttributes(options: AuthFetchUserAttributeOperation.Request.Options? = nil,
                             listener: AuthFetchUserAttributeOperation.ResultListener?)
    -> AuthFetchUserAttributeOperation {

        let options = options ?? AuthFetchUserAttributesRequest.Options()
        let request = AuthFetchUserAttributesRequest(options: options)
        let operation = AWSAuthFetchUserAttributesOperation(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory,
            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func update(userAttribute: AuthUserAttribute,
                options: AuthUpdateUserAttributeOperation.Request.Options? = nil,
                listener: AuthUpdateUserAttributeOperation.ResultListener?) -> AuthUpdateUserAttributeOperation {

        let options = options ?? AuthUpdateUserAttributeRequest.Options()
        let request = AuthUpdateUserAttributeRequest(userAttribute: userAttribute, options: options)
        let operation = AWSAuthUpdateUserAttributeOperation(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory,
            resultListener: listener)
        queue.addOperation(operation)
        return operation

    }

    func update(userAttributes: [AuthUserAttribute],
                options: AuthUpdateUserAttributesOperation.Request.Options? = nil,
                listener: AuthUpdateUserAttributesOperation.ResultListener?)
    -> AuthUpdateUserAttributesOperation {

        let options = options ?? AuthUpdateUserAttributesRequest.Options()
        let request = AuthUpdateUserAttributesRequest(userAttributes: userAttributes, options: options)
        let operation = AWSAuthUpdateUserAttributesOperation(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory,
            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil,
                                listener: AuthAttributeResendConfirmationCodeOperation.ResultListener?)
    -> AuthAttributeResendConfirmationCodeOperation {

        let options = options ?? AuthAttributeResendConfirmationCodeRequest.Options()
        let request = AuthAttributeResendConfirmationCodeRequest(attributeKey: attributeKey, options: options)
        let operation = AWSAuthAttributeResendConfirmationCodeOperation(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory,
            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func confirm(userAttribute: AuthUserAttributeKey,
                 confirmationCode: String,
                 options: AuthConfirmUserAttributeOperation.Request.Options? = nil,
                 listener: AuthConfirmUserAttributeOperation.ResultListener?)
    -> AuthConfirmUserAttributeOperation {

        let options = options ?? AuthConfirmUserAttributeRequest.Options()
        let request = AuthConfirmUserAttributeRequest(
            attributeKey: userAttribute,
            confirmationCode: confirmationCode,
            options: options)
        let operation = AWSAuthConfirmUserAttributeOperation(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory,
            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options? = nil) async throws {
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword, options: options)
        let task = AWSAuthChangePasswordTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    func getCurrentUser() async -> AuthUser? {
        let authState = await authStateMachine.currentMachineState
        if case .configured(let authenticationState, _) = authState,
           case .signedIn(let signInData) = authenticationState {
            let authUser = AWSCognitoAuthUser(username: signInData.userName, userId: signInData.userId)
            return authUser
        } else {
            return nil
        }
    }

    func getCurrentUser(closure: @escaping (Result<AuthUser?, Error>) -> Void) {
        authStateMachine.getCurrentState { authState in
            if case .configured(let authenticationState, _) = authState,
               case .signedIn(let signInData) = authenticationState {
                let authUser = AWSCognitoAuthUser(username: signInData.userName, userId: signInData.userId)
                closure(.success(authUser))
            } else {
                closure(.success(nil))
            }
        }
    }
}
