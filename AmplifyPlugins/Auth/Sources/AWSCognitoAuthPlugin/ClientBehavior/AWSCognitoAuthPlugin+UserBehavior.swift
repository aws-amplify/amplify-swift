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
        return try await taskQueue.sync {
            return try await task.value
        } as! [AuthUserAttribute]
    }

    func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options? = nil) async throws -> AuthUpdateAttributeResult {

        let options = options ?? AuthUpdateUserAttributeRequest.Options()
        let request = AuthUpdateUserAttributeRequest(userAttribute: userAttribute, options: options)
        let task = AWSAuthUpdateUserAttributeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await taskQueue.sync {
            return try await task.value
        } as! AuthUpdateAttributeResult
    }

    func update(userAttributes: [AuthUserAttribute],
                options: AuthUpdateUserAttributesRequest.Options? = nil)
    async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {

        let options = options ?? AuthUpdateUserAttributesRequest.Options()
        let request = AuthUpdateUserAttributesRequest(userAttributes: userAttributes, options: options)
        let task = AWSAuthUpdateUserAttributesTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await taskQueue.sync {
            return try await task.value
        } as! [AuthUserAttributeKey: AuthUpdateAttributeResult]
    }

    func resendConfirmationCode(forUserAttributeKey userAttributeKey: AuthUserAttributeKey,
                                options: AuthAttributeResendConfirmationCodeRequest.Options? = nil) async throws -> AuthCodeDeliveryDetails {

        let options = options ?? AuthAttributeResendConfirmationCodeRequest.Options()
        let request = AuthAttributeResendConfirmationCodeRequest(
            attributeKey: userAttributeKey, options: options)
        let task = AWSAuthAttributeResendConfirmationCodeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await taskQueue.sync {
            return try await task.value
        } as! AuthCodeDeliveryDetails
    }

    func confirm(userAttribute: AuthUserAttributeKey, confirmationCode: String, options: AuthConfirmUserAttributeRequest.Options? = nil) async throws {
        let options = options ?? AuthConfirmUserAttributeRequest.Options()
        let request = AuthConfirmUserAttributeRequest(
            attributeKey: userAttribute,
            confirmationCode: confirmationCode,
            options: options)
        let task = AWSAuthConfirmUserAttributeTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        _ = try await taskQueue.sync {
            return try await task.value
        }
    }

    func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options? = nil) async throws {
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword, options: options)
        let task = AWSAuthChangePasswordTask(request, authStateMachine: authStateMachine, userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        _ = try await taskQueue.sync {
            return try await task.value
        }
    }

    func getCurrentUser() async throws -> AuthUser {

        await AWSAuthTaskHelper(authStateMachine: authStateMachine).didStateMachineConfigured()
        let authState = await authStateMachine.currentState

        guard case .configured(let authenticationState, _) = authState else {
            throw AuthError.configuration(
                "Plugin not configured",
                AuthPluginErrorConstants.configurationError)
        }

        switch authenticationState {
        case .notConfigured:
            throw AuthError.configuration("UserPool configuration is missing", AuthPluginErrorConstants.configurationError)
        case .signedIn(let signInData):
            let authUser = AWSAuthUser(username: signInData.username, userId: signInData.userId)
            return authUser
        case .signedOut, .configured:
            throw AuthError.signedOut(
                "There is no user signed in to retrieve current user",
                "Call Auth.signIn to sign in a user and then call Auth.getCurrentUser", nil)
        case .error(let authNError):
            throw authNError.authError
        default:
            throw AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError, nil)
        }
    }
}
