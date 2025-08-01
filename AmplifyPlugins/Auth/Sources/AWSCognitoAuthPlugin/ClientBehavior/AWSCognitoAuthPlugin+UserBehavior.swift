//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// swiftlint:disable force_cast
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

    @available(*, deprecated, renamed: "sendVerificationCode(forUserAttributeKey:options:)")
    func resendConfirmationCode(
        forUserAttributeKey userAttributeKey: AuthUserAttributeKey,
        options: AuthAttributeResendConfirmationCodeRequest.Options? = nil
    ) async throws -> AuthCodeDeliveryDetails {

        let options = options ?? AuthAttributeResendConfirmationCodeRequest.Options()
        let request = AuthAttributeResendConfirmationCodeRequest(
            attributeKey: userAttributeKey, options: options)
        let task = AWSAuthAttributeResendConfirmationCodeTask(
            request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory
        )
        return try await taskQueue.sync {
            return try await task.value
        } as! AuthCodeDeliveryDetails
    }

    func sendVerificationCode(
        forUserAttributeKey userAttributeKey:
        AuthUserAttributeKey,
        options: AuthSendUserAttributeVerificationCodeRequest.Options? = nil
    ) async throws -> AuthCodeDeliveryDetails {
        let options = options ?? AuthSendUserAttributeVerificationCodeRequest.Options()
        let request = AuthSendUserAttributeVerificationCodeRequest(
            attributeKey: userAttributeKey, options: options)
        let task = AWSAuthSendUserAttributeVerificationCodeTask(
            request, authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory)
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

    func getCurrentUser() async throws -> any AuthUser {
        let taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        return try await taskHelper.getCurrentUser()
    }
}
// swiftlint:enable force_cast
