//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

class AWSAuthFetchUserAttributeTask: AuthFetchUserAttributeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthFetchUserAttributesRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchUserAttributesAPI
    }

    init(_ request: AuthFetchUserAttributesRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> [AuthUserAttribute] {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await getUserAttributes(with: accessToken)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func getUserAttributes(with accessToken: String) async throws -> [AuthUserAttribute] {
        let userPoolService = try userPoolFactory()
        let input = GetUserInput(accessToken: accessToken)
        let result = try await userPoolService.getUser(input: input)

        guard let attributes = result.userAttributes else {
            let authError = AuthError.unknown("Unable to get Auth code delivery details", nil)
            throw authError
        }

        let mappedAttributes: [AuthUserAttribute] = attributes.compactMap { oldAttribute in
            guard let attributeName = oldAttribute.name,
                  let attributeValue = oldAttribute.value else {
                return nil
            }
            return AuthUserAttribute(AuthUserAttributeKey(rawValue: attributeName),
                                     value: attributeValue)
        }
        return mappedAttributes
    }

}
