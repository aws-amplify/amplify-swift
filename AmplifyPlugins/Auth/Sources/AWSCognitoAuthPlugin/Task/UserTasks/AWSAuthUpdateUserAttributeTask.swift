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

class AWSAuthUpdateUserAttributeTask: AuthUpdateUserAttributeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthUpdateUserAttributeRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private var stateMachineToken: AuthStateMachineToken?
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.updateUserAttributeAPI
    }

    init(_ request: AuthUpdateUserAttributeRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(stateMachineToken: self.stateMachineToken, authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthUpdateAttributeResult {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await updateUserAttribute(with: accessToken)
        } catch let error as UpdateUserAttributesOutputError {
            throw error.authError
        } catch let error as AuthError {
            dispatch(result: .failure(error))
            throw error
        } catch let error {
            let error = AuthError.unknown("Unable to execute auth task", error)
            throw error
        }
    }

    func updateUserAttribute(with accessToken: String) async throws -> AuthUpdateAttributeResult {
        let clientMetaData = (request.options.pluginOptions as? AWSUpdateUserAttributeOptions)?.metadata ?? [:]

        let finalResult = try await UpdateAttributesOperationHelper.update(
            attributes: [request.userAttribute],
            accessToken: accessToken,
            userPoolFactory: userPoolFactory,
            clientMetaData: clientMetaData)

        guard let attributeResult = finalResult[request.userAttribute.key] else {
            let authError = AuthError.unknown("Attribute to be updated does not exist in the result", nil)
            throw authError
        }

        return attributeResult
    }
}
