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

class AWSAuthChangePasswordTask: AuthChangePasswordTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthChangePasswordRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.changePasswordAPI
    }

    init(_ request: AuthChangePasswordRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            try await changePassword(with: accessToken)
        } catch let error as ChangePasswordOutputError {
            throw error.authError
        } catch let error {
            throw AuthError.configuration("Unable to execute auth task", AuthPluginErrorConstants.configurationError, error)
        }
    }

    func changePassword(with accessToken: String) async throws {
        let userPoolService = try userPoolFactory()
        let input = ChangePasswordInput(accessToken: accessToken, previousPassword: request.oldPassword, proposedPassword: request.newPassword)
        _ = try await userPoolService.changePassword(input: input)
    }
}
