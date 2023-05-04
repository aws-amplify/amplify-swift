//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

class AWSAuthUpdateUserAttributesTask: AuthUpdateUserAttributesTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthUpdateUserAttributesRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.updateUserAttributesAPI
    }

    init(_ request: AuthUpdateUserAttributesRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await updateUserAttribute(with: accessToken)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func updateUserAttribute(with accessToken: String) async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
        let clientMetaData = (request.options.pluginOptions as? AWSAuthUpdateUserAttributesOptions)?.metadata ?? [:]
        let finalResult = try await UpdateAttributesOperationHelper.update(
            attributes: request.userAttributes,
            accessToken: accessToken,
            userPoolFactory: userPoolFactory,
            clientMetaData: clientMetaData)
        return finalResult
    }
}
